class ViviendaModel {
  final String? id;
  final DateTime? fechaRegistro;
  final String? inspectorId;
  final String? nombrePropietario;
  final String? telefono;
  final String? direccion;
  final String? colonia;
  final String? localidad;
  final int habitantesTotal;
  final int ninos;
  final int adultosMayores;
  final int personasDiscapacidad;
  final String? tipoConstruccion;
  final int niveles;
  final int? anioConstruccion;
  final bool grietasMuros;
  final bool grietasPiso;
  final bool separacionMuroTecho;
  final bool hundimiento;
  final bool inclinacion;
  final bool fracturaReciente;
  final String? nivelDano;
  final String? observaciones;
  final double? lat;
  final double? lon;
  final double? precisionGps;
  final double? altitud;
  final double? distanciaFalla;
  final bool sobreFalla;
  final double? indiceRiesgoVivienda;
  final bool synced;

  ViviendaModel({
    this.id,
    this.fechaRegistro,
    this.inspectorId,
    this.nombrePropietario,
    this.telefono,
    this.direccion,
    this.colonia,
    this.localidad,
    this.habitantesTotal = 0,
    this.ninos = 0,
    this.adultosMayores = 0,
    this.personasDiscapacidad = 0,
    this.tipoConstruccion,
    this.niveles = 1,
    this.anioConstruccion,
    this.grietasMuros = false,
    this.grietasPiso = false,
    this.separacionMuroTecho = false,
    this.hundimiento = false,
    this.inclinacion = false,
    this.fracturaReciente = false,
    this.nivelDano,
    this.observaciones,
    this.lat,
    this.lon,
    this.precisionGps,
    this.altitud,
    this.distanciaFalla,
    this.sobreFalla = false,
    this.indiceRiesgoVivienda,
    this.synced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre_propietario': nombrePropietario,
      'telefono': telefono,
      'direccion': direccion,
      'colonia': colonia,
      'localidad': localidad,
      'habitantes_total': habitantesTotal,
      'ninos': ninos,
      'adultos_mayores': adultosMayores,
      'personas_discapacidad': personasDiscapacidad,
      'tipo_construccion': tipoConstruccion,
      'niveles': niveles,
      'anio_construccion': anioConstruccion,
      'grietas_muros': grietasMuros,
      'grietas_piso': grietasPiso,
      'separacion_muro_techo': separacionMuroTecho,
      'hundimiento': hundimiento,
      'inclinacion': inclinacion,
      'fractura_reciente': fracturaReciente,
      'nivel_dano': nivelDano,
      'observaciones': observaciones,
      'lat': lat,
      'lon': lon,
      'altitud': altitud,
      'precision_gps': precisionGps,
    };
  }

  static ViviendaModel fromJson(Map<String, dynamic> json) {
    return ViviendaModel(
      id: json['id'] as String?,
      nombrePropietario: json['nombre_propietario'] as String?,
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      colonia: json['colonia'] as String?,
      localidad: json['localidad'] as String?,
      habitantesTotal: (json['habitantes_total'] as num?)?.toInt() ?? 0,
      ninos: (json['ninos'] as num?)?.toInt() ?? 0,
      adultosMayores: (json['adultos_mayores'] as num?)?.toInt() ?? 0,
      personasDiscapacidad: (json['personas_discapacidad'] as num?)?.toInt() ?? 0,
      tipoConstruccion: json['tipo_construccion'] as String?,
      niveles: (json['niveles'] as num?)?.toInt() ?? 1,
      anioConstruccion: (json['anio_construccion'] as num?)?.toInt(),
      grietasMuros: json['grietas_muros'] == true,
      grietasPiso: json['grietas_piso'] == true,
      separacionMuroTecho: json['separacion_muro_techo'] == true,
      hundimiento: json['hundimiento'] == true,
      inclinacion: json['inclinacion'] == true,
      fracturaReciente: json['fractura_reciente'] == true,
      nivelDano: json['nivel_dano'] as String?,
      observaciones: json['observaciones'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      precisionGps: (json['precision_gps'] as num?)?.toDouble(),
      altitud: (json['altitud'] as num?)?.toDouble(),
      distanciaFalla: (json['distancia_falla'] as num?)?.toDouble(),
      sobreFalla: json['sobre_falla'] == true,
      indiceRiesgoVivienda: (json['indice_riesgo_vivienda'] as num?)?.toDouble(),
      synced: json['synced'] == true,
    );
  }
}
