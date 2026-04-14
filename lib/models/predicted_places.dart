class PredictedPlaces{
  String? place_id;
  String? main_text;
  String? secondary_text;
  double? latitude;
  double? longitude;

  PredictedPlaces({
    this.place_id,
    this.main_text,
    this.secondary_text,
    this.latitude,
    this.longitude,
  });

  PredictedPlaces.fromJson(Map<String, dynamic> jsonData){
    // Nominatim usa 'place_id' como entero, lo convertimos a string
    place_id = jsonData["place_id"]?.toString() ?? jsonData["osm_id"]?.toString() ?? '';

    // 'name' puede ser null en Nominatim, usar display_name como fallback
    main_text = jsonData["name"]?.toString() ?? jsonData["display_name"]?.toString()?.split(",")?.first ?? 'Sin nombre';

    // display_name es la dirección completa
    secondary_text = jsonData["display_name"]?.toString() ?? '';

    // Parsear lat/lon con manejo de errores
    try {
      latitude = jsonData['lat'] != null ? double.parse(jsonData['lat'].toString()) : null;
    } catch (e) {
      latitude = null;
    }

    try {
      longitude = jsonData['lon'] != null ? double.parse(jsonData['lon'].toString()) : null;
    } catch (e) {
      longitude = null;
    }
  }

}