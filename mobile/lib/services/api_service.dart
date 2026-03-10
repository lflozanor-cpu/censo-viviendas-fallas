import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vivienda_model.dart';

class ApiService extends http.BaseClient {
  static const String urlLocal = 'http://192.168.0.5:8000/api';
  static const String urlCampoDefault = 'https://downrightly-rollable-henry.ngrok-free.dev/api';

  String baseUrl;
  String? _token;

  ApiService({String? initialBaseUrl})
      : baseUrl = initialBaseUrl ?? urlCampoDefault;

  void setBaseUrl(String url) {
    baseUrl = url;
  }
  final _client = http.Client();

  void setToken(String? token) => _token = token;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Content-Type'] = 'application/json';
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    return _client.send(request);
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final r = await _client
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return null;
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<ViviendaModel>> getViviendas() async {
    final r = await get(Uri.parse('$baseUrl/viviendas'));
    if (r.statusCode != 200) return [];
    final list = jsonDecode(r.body) as List;
    return list.map((e) => ViviendaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ViviendaModel?> getVivienda(String id) async {
    final r = await get(Uri.parse('$baseUrl/viviendas/$id'));
    if (r.statusCode != 200) return null;
    return ViviendaModel.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<ViviendaModel?> createVivienda(ViviendaModel v) async {
    final r = await post(
      Uri.parse('$baseUrl/viviendas'),
      body: jsonEncode(v.toJson()),
    );
    if (r.statusCode != 200 && r.statusCode != 201) return null;
    return ViviendaModel.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<ViviendaModel?> updateVivienda(String id, ViviendaModel v) async {
    final r = await put(
      Uri.parse('$baseUrl/viviendas/$id'),
      body: jsonEncode(v.toJson()),
    );
    if (r.statusCode != 200) return null;
    return ViviendaModel.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<bool> addFoto(String viviendaId, String tipoFoto, String url, {double? lat, double? lon}) async {
    final r = await post(
      Uri.parse('$baseUrl/viviendas/$viviendaId/fotos'),
      body: jsonEncode({
        'vivienda_id': viviendaId,
        'tipo_foto': tipoFoto,
        'url': url,
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
      }),
    );
    return r.statusCode == 200 || r.statusCode == 201;
  }

  Future<Map<String, dynamic>?> getEstadisticas() async {
    final r = await get(Uri.parse('$baseUrl/estadisticas'));
    if (r.statusCode != 200) return null;
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// GeoJSON FeatureCollection con las fallas geológicas (LineString).
  Future<Map<String, dynamic>> getFallasGeoJson() async {
    final r = await get(Uri.parse('$baseUrl/fallas/geojson'));
    if (r.statusCode != 200) return {'type': 'FeatureCollection', 'features': []};
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Descarga el Excel de viviendas (requiere autenticación). Devuelve null si falla.
  Future<List<int>?> getExportExcelBytes() async {
    final r = await get(Uri.parse('$baseUrl/export/excel'));
    if (r.statusCode != 200) return null;
    return r.bodyBytes;
  }
}
