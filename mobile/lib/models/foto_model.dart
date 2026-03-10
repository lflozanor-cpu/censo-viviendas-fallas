class FotoModel {
  final String? id;
  final String viviendaId;
  final String tipoFoto; // fachada, grietas, interior, terreno
  final String url;      // path local o URL remota
  final DateTime? fecha;
  final double? lat;
  final double? lon;

  FotoModel({
    this.id,
    required this.viviendaId,
    required this.tipoFoto,
    required this.url,
    this.fecha,
    this.lat,
    this.lon,
  });

  Map<String, dynamic> toJson() {
    return {
      'vivienda_id': viviendaId,
      'tipo_foto': tipoFoto,
      'url': url,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
    };
  }
}
