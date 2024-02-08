String displayLocationString(dynamic locationValue){
  return locationValue != null?
  (locationValue!.locationName!.length == 0)?
  'No se obtiene direccion'
      :
  (locationValue!.locationName!.length < 25)?
  locationValue!.locationName!
      :
  (locationValue!.locationName!).substring(0, 24)+'...'
      : 'No se obtiene direccion';

}

String displayHistoryLocationString(dynamic locationValue){
  return locationValue != null?
  (locationValue!.length == 0)?
  'No se obtiene direccion'
      :
  (locationValue!.length < 40)?
  locationValue
      :
  (locationValue!).substring(0, 39)+'...'
      : 'No se obtiene direccion';

}

