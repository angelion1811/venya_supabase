import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ven_app/Assistants/assistant_methods.dart';
import 'package:ven_app/Assistants/geofire_assistant.dart';
import 'package:ven_app/Services/supabase_service.dart';
import 'package:ven_app/Helpers/custom_functions.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/infoHandler/app_info.dart';
import 'package:ven_app/models/active_nearby_available_drivers.dart';
import 'package:ven_app/screens/drawer_screen.dart';
import 'package:ven_app/screens/precise_dropoff_location_screen.dart';
import 'package:ven_app/screens/precise_pickup_location_screen.dart';
import 'package:ven_app/screens/trip_summary_screen.dart';
import 'package:ven_app/splashScreen/splash_screen.dart';
import 'package:ven_app/widgets/card_vehicle_type.dart';
import 'package:ven_app/widgets/progress_dialog.dart';
import '../Assistants/black_theme_google_map.dart';
import '../widgets/pay_fare_amount_dialog.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../Assistants/socket_assistant.dart';
import '../models/directions.dart';
import '../models/vehicle_type_model.dart';
import '../models/fare_hour_multiplier_model.dart';

Future<void> _makePhoneCall(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  LatLng? pickLocation;
  loc.Location location = loc.Location();
  String? _address;

  final socketAssistant = SocketAssistant();

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

   late IO.Socket socket;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> _scafforState = GlobalKey<ScaffoldState>();
  double searchLocationContainerHeight = 220;
  double waitingResponseFromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;
  double suggestedRidesContainerHeight = 0;
  double searchingForDriverContainerHeight = 0;
  Position? userCurrentPosition;
  var geolocation = Geolocator();
  LocationPermission? _locationPermission;
  double bottonPaddingOfMap = 0;
  List<LatLng> pLineCoordinatedList = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  String userName =  '';
  String useEmail = '';
  bool openNavigatorDrawer = true;
  bool activeNearbyDriverKeysLoaded = false;
  BitmapDescriptor? activeNearbyIcon;
  DatabaseReference? referenceRideRequest;
  String selectedVehicleType = "";
  String estimatedFare = "0.00";
  List<VehicleType>? _vehicleTypes;
  List<FareHourMultiplier> _fareHourMultipliers = [];
  Map<String, String> _vehicleTypeImagePaths = {};
  Map<String, double> _vehicleTypeImageScales = {};
  String driverRideStatus = "Driver is coming";
  StreamSubscription<DatabaseEvent>? tripRideRequestInfoStreamSubscription;
  StreamSubscription<DatabaseEvent>? streamRideRequestStatus;
  StreamSubscription<DatabaseEvent>? streamRideRequestDriverLocation;
  List<ActiveNearByAvailableDrivers> onlineNearByAvailableDriversList = [];
  String userRideRequestStatus = "";
  bool requestPositionInfo = true;
  // Oferta de tarifa que el pasajero puede ingresar manualmente
  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _packageController = TextEditingController();
  final TextEditingController _waterLitersController = TextEditingController();


  locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;
    LatLng latLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 15);
    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    initializeGeoFireListener();

    // Solo buscamos la dirección automáticamente si no hay una ya seleccionada
    var appInfo = Provider.of<AppInfo>(context, listen: false);
    if (appInfo.userPickUpLocation == null) {
      String humaneReableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(userCurrentPosition!.latitude, userCurrentPosition!.longitude, context);
      print("this is our address = " + humaneReableAddress);
      
      Directions userPickAddress = Directions();
      userPickAddress.locationLatitude = userCurrentPosition!.latitude;
      userPickAddress.locationLongitude = userCurrentPosition!.longitude;
      userPickAddress.locationName = humaneReableAddress;
      appInfo.updatePickUpLocationAddress(userPickAddress);
    }
    
    userName = userModelCurrentInfo!.names!;
    useEmail = userModelCurrentInfo!.email!;
    AssistantMethods.readTripsHistoryFromSupabase(context);
  }

  double _getHourMultiplier(String vehicleTypeId) {
    if (_fareHourMultipliers.isEmpty) return 1.0;
    for (final multiplier in _fareHourMultipliers) {
      if (multiplier.vehicleTypeId == vehicleTypeId && multiplier.isActive) {
        if (multiplier.isCurrentTimeInRange()) {
          return multiplier.multiplier;
        }
      }
    }
    return 1.0;
  }

  Future<String> _resolveAssetPath(String? iconName) async {
    const fallback = 'images/car.png';
    if (iconName == null || iconName.isEmpty) return fallback;

    final path = 'images/$iconName.png';
    try {
      await rootBundle.load(path);
      return path;
    } catch (_) {
      return fallback;
    }
  }

  VehicleType? _getSelectedVehicleTypeObj() {
    if (_vehicleTypes == null || selectedVehicleType.isEmpty) return null;
    try {
      return _vehicleTypes!.firstWhere((v) => v.key == selectedVehicleType);
    } catch (_) {
      return null;
    }
  }

  List<Widget> _buildVehicleTypeCards(bool darkTheme) {
    if (_vehicleTypes == null || _vehicleTypes!.isEmpty) {
      return [];
    }

    final baseFare = tripDirectionDetailsInfo != null
        ? AssistantMethods.calculateFareAroundFromOriginToDestination(tripDirectionDetailsInfo!)
        : 0.0;

    return _vehicleTypes!.map((vt) {
      final bool isSelected = selectedVehicleType == vt.key;
      final String fareDisplay;
      final String estimatedFareValue;

      if (vt.hasCustomFare) {
        fareDisplay = '';
        estimatedFareValue = '0.00';
      } else {
        final hourMult = _getHourMultiplier(vt.id);
        final fare = (baseFare * vt.fareMultiplier * hourMult).toStringAsFixed(2);
        fareDisplay = tripDirectionDetailsInfo != null ? '\$ $fare' : '';
        estimatedFareValue = fare;
      }

      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: CardVehicleType(
          darkTheme: darkTheme,
          assetImageString: _vehicleTypeImagePaths[vt.key] ?? 'images/car.png',
          assetImageScale: _vehicleTypeImageScales[vt.key] ?? 9,
          selectedVehicleType: selectedVehicleType,
          vehicleType: vt.key,
          vehicleTypeString: vt.name,
          amountString: fareDisplay,
          onTap: () => setState(() {
            selectedVehicleType = vt.key;
            estimatedFare = estimatedFareValue;
            if (!vt.hasCustomFare) {
              _waterLitersController.clear();
            }
          }),
        ),
      );
    }).toList();
  }

  bool _vehicleTypeHasExtraFields(String key) {
    final vt = _vehicleTypes?.firstWhere(
      (v) => v.key == key,
      orElse: () => VehicleType(
        id: '', key: key, name: '', fareMultiplier: 1, hasCustomFare: false, isActive: true, displayOrder: 0,
      ),
    );
    return vt?.extraFields != null && vt!.extraFields!.isNotEmpty;
  }

  Map<String, dynamic>? _getExtraFieldConfig(String vehicleKey, String fieldKey) {
    final vt = _vehicleTypes?.firstWhere(
      (v) => v.key == vehicleKey,
      orElse: () => VehicleType(
        id: '', key: vehicleKey, name: '', fareMultiplier: 1, hasCustomFare: false, isActive: true, displayOrder: 0,
      ),
    );
    if (vt?.extraFields == null) return null;
    for (final field in vt!.extraFields!) {
      if (field is Map && field['field_key'] == fieldKey) {
        return Map<String, dynamic>.from(field);
      }
    }
    return null;
  }

  initializeGeoFireListener(){
    //aqui se toman los datos de la tabla objeto de firebase
    Geofire.initialize("activeDrivers");
    Geofire.queryAtLocation(userCurrentPosition!.latitude, userCurrentPosition!.longitude, 10)!.listen((map) {
      //print(map);
      if(map != null){
        var callBack = map["callBack"];

        switch(callBack){
        // whenever any driver become active/online
          case Geofire.onKeyEntered:
            GeoFireAssistant.activeNearByAvailableDriversList.clear();
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers = ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map["latitude"];
            activeNearByAvailableDrivers.locationLongitude = map["longitude"];
            activeNearByAvailableDrivers.driverId = map["key"];
            GeoFireAssistant.activeNearByAvailableDriversList.add(activeNearByAvailableDrivers);
            if(activeNearbyDriverKeysLoaded == true){
              displayActiveDriversOnUserMap();
            }
            break;

        // whenever any driver become non-active/online
          case Geofire.onKeyExited:
            print("map key: ${map["key"]}");
            GeoFireAssistant.deleteOfflineDriverFromList(map["key"]);
            displayActiveDriversOnUserMap();
            break;

        //whenever driver moves - update driver location
          case Geofire.onKeyMoved:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers = ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map["latitude"];
            activeNearByAvailableDrivers.locationLongitude = map["longitude"];
            activeNearByAvailableDrivers.driverId = map["key"];
            GeoFireAssistant.updateActiveNearByAvailableDriverLocation(activeNearByAvailableDrivers);
            displayActiveDriversOnUserMap();
            break;

        //display those online active drivers on user's map
          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded = true;
            displayActiveDriversOnUserMap();
            break;
        }
      }
      setState(() {});
    });
  }

  displayActiveDriversOnUserMap(){
    setState(() {
      markerSet.clear();
      circleSet.clear();
      Set<Marker> driversMarkerSet = Set<Marker>();

      for(ActiveNearByAvailableDrivers eachDriver in GeoFireAssistant.activeNearByAvailableDriversList){
        LatLng eachDriverActivePosition = LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);

        Marker marker = Marker(
            markerId: MarkerId(eachDriver.driverId!),
            position: eachDriverActivePosition,
            icon: activeNearbyIcon!,
            rotation: 360,
        );

        driversMarkerSet.add(marker);
      }
      setState(()=>markerSet = driversMarkerSet);
    });
  }

  createActiveNearByDriverIconMarker(){
    print("createActiveNearByDriverIconMarker");
    print(activeNearbyIcon.toString());
    if(activeNearbyIcon == null){
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(1,1));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car_gpsmap.png").then((value){
        activeNearbyIcon = value;
      });
    }
  }

  Future<void> drawPolyLineFromOriginToDestination(bool darkTheme) async {
    var originPosition = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(originPosition!.locationLatitude!, originPosition!.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!, destinationPosition!.locationLongitude!);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(message: "Por favor espere...",)
    );

    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);
    
    Navigator.pop(context);

    if (directionDetailsInfo == null) {
      Fluttertoast.showToast(msg: "No se pudo encontrar una ruta entre los puntos.");
      return;
    }

    setState(()=>tripDirectionDetailsInfo =  directionDetailsInfo);

    pLineCoordinatedList.clear();

    if(directionDetailsInfo.e_points!.isNotEmpty){
        var list = directionDetailsInfo.e_points;
        for(int i=0; i< list.length; i++){
          double lat = (list[i][1] is int)? double.parse(list[i][1].toString()):list[i][1];
          double long = (list[i][1] is int)? double.parse(list[i][0].toString()):list[i][0];
          pLineCoordinatedList.add(LatLng(lat,long));
        }
    }
    setState(()=> polylineSet.clear());

    setState(() {
      Polyline polyline = Polyline(
        color: darkTheme? Colors.amberAccent: Colors.blue,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinatedList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng = LatLngBounds(
          southwest: destinationLatLng,
          northeast: originLatLng,
      );
    } else if (originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.latitude),
      );
    } else if (originLatLng.latitude > destinationLatLng.latitude){
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.latitude),
      );
    } else {
      boundsLatLng = LatLngBounds(
          southwest: originLatLng ,
          northeast: destinationLatLng
      );
    }

    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: MarkerId("originID"),
      infoWindow: InfoWindow(title: originPosition.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
    );

    Marker destinationMarker = Marker(
        markerId: MarkerId("destinationID"),
        infoWindow: InfoWindow(title: destinationPosition.locationName, snippet: "Destination"),
        position: destinationLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
    );

    setState(() {
      markerSet.add(originMarker);
      markerSet.add(destinationMarker);
    });

    Circle originCircle = Circle(
        circleId: CircleId("originID"),
        fillColor: Colors.green,
        radius: 12,
        strokeWidth: 3,
        strokeColor: Colors.white,
        center: originLatLng
    );

    Circle destinationCircle = Circle(
        circleId: CircleId("destinationID"),
        fillColor: Colors.red,
        radius: 12,
        strokeWidth: 3,
        strokeColor: Colors.white,
        center: destinationLatLng
    );

    setState(() {
      circleSet.add(originCircle);
      circleSet.add(destinationCircle);
    });

  }

  void showUISearchingForDriversContainer(){
    print("llego aqui showUISearchingForDriversContainer");
    setState(()=>searchingForDriverContainerHeight = 200);
  }

  Future<void> showSuggestedRidesContainer() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => ProgressDialog(message: "Cargando tarifas...",)
    );

    try {
      final types = await SupabaseService.getActiveVehicleTypes();
      final multipliers = await SupabaseService.getActiveFareHourMultipliers();
      final paths = <String, String>{};
      final scales = <String, double>{};

      for (final vt in types) {
        paths[vt.key] = await _resolveAssetPath(vt.iconName);
        scales[vt.key] = paths[vt.key] == 'images/CNG.png' ? 4.0 : 9.0;
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _vehicleTypes = types;
          _fareHourMultipliers = multipliers;
          _vehicleTypeImagePaths = paths;
          _vehicleTypeImageScales = scales;
          suggestedRidesContainerHeight = 550;
          bottonPaddingOfMap = 550;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      log("Error al cargar tarifas y vehículos: $e");
      Fluttertoast.showToast(msg: "Error al obtener tarifas actuales. Inténtelo de nuevo.");
    }
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();

    if(_locationPermission == LocationPermission.denied){
      _locationPermission = await Geolocator.requestPermission();
    } else {
      locateUserPosition();
    }
  }

  saveRideRequestInformation(String selectedVehicleType, bool darkTheme){
    referenceRideRequest = FirebaseDatabase.instance.ref().child("All Ride Requests").push();

    var originLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map<String, dynamic> originLocationMap = {
      //"key": value"
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };

    Map<String, dynamic> destinationLocationMap = {
      //"key": value"
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };

    // Si el pasajero dejó el campo vacío, guardamos cadena vacía (el conductor verá el estimado)
    final String fareOffer = _fareController.text.trim();
    final String packageDetails = _packageController.text.trim();
    final String waterLiters = _waterLitersController.text.trim();

    Map<String, dynamic> rideInformationMap = {
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time":DateTime.now().toString(),
      "userName": "${userModelCurrentInfo!.names} ${userModelCurrentInfo!.surnames}",
      "userPhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locationName,
      "destinationAddress": destinationLocation.locationName,
      "status":"waiting",
      "driverId":"-",
      "offeredFare": fareOffer,  // oferta del pasajero (vacía si no se ingresó)
      "estimatedFare": (_getSelectedVehicleTypeObj()?.hasCustomFare ?? false) ? 'Por definir por el conductor' : estimatedFare, // tarifa estimada
      "packageDetails": packageDetails, // detalles de la encomienda
      "waterLiters": waterLiters, // litros de agua
      "userId": SupabaseService.currentUser?.id,
    };

    referenceRideRequest!.set(rideInformationMap);

/*

    tripRideRequestInfoStreamSubscription = referenceRideRequest!.onValue.listen((eventSnap) async{
      if(eventSnap.snapshot.value == null){
        return;
      }


      if((eventSnap.snapshot.value as Map)["status"] != null){
        setState(()=> userRideRequestStatus = (eventSnap.snapshot.value as Map)["status"].toString());
        print("userRideRequestStatus: ${userRideRequestStatus}");
      }

      if((eventSnap.snapshot.value as Map)["driverLocation"] != null){
        double driverCurrentPositionLat = double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["latitude"].toString());
        double driverCurrentPositionLng = double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["longitude"].toString());

        LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);

        //status = acepted
        (userRideRequestStatus == "accepted")?
          updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng):null;

        //status = arrived
        (userRideRequestStatus == "arrived")?
          setState(() => driverRideStatus = "El Chofer ha llegado"):null;

        //status = on trip
        (userRideRequestStatus == "ontrip")?
          updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng):null;

        if(userRideRequestStatus == "ended"){
          if((eventSnap.snapshot.value as Map)["fareAmount"] != null){
            double fareAmount = double.parse((eventSnap.snapshot.value as Map)["fareAmount"].toString());

            var response = await showDialog(
                context: context,
                builder: (BuildContext context) => PayFareAmountDialog(
                  fareAmount: fareAmount,
                )
            );

            if(response == "Cash Paid"){
              //user can rate the driver now
              if((eventSnap.snapshot.value as Map)["driverId"] != null){
                String assignedDriverId = (eventSnap.snapshot.value as Map)["driverId"].toString();
                Navigator.push(context, MaterialPageRoute(builder: (c)=> RateDriverScreen(
                  assignedDriverId: assignedDriverId,
                )));
                rideInformationMap['_id'] = referenceRideRequest!.key;
                var responseRequest = await SupabaseService.saveRide(rideInformationMap);
                referenceRideRequest!.onDisconnect();
                tripRideRequestInfoStreamSubscription!.cancel();
                referenceRideRequest!.remove();
              }
            }
          }
        }
      }
    });

 */

    onlineNearByAvailableDriversList = GeoFireAssistant.activeNearByAvailableDriversList;
    searchNearestOnlineDrivers(selectedVehicleType, rideInformationMap, darkTheme);
  }

  searchNearestOnlineDrivers(String selectedVehicleType, Map<String, dynamic> rideInformationMap, bool darkTheme) async {
    showUISearchingForDriversContainer();

    if(onlineNearByAvailableDriversList.length == 0){
      //cancel/delete the ride request Information
      referenceRideRequest!.remove();
      setState(() {
        polylineSet.clear();
        markerSet.clear();
        circleSet.clear();
        pLineCoordinatedList.clear();
      });

      Fluttertoast.showToast(msg: "No hay choferes cercas disponibles");
      Fluttertoast.showToast(msg: "Buscar de nuevo. \n Reiniciando Aplicacion");
      Future.delayed(Duration(milliseconds: 4000), (){
        referenceRideRequest!.remove();
        Navigator.push(context, MaterialPageRoute(builder: (c)=> SplashScreen()));
      });
      return;
    }
    //aqui se obtiene el resto de la informacion de los condutores que estan conectados
    await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

    //en este ciclo se le envia la notificacion push con el token que tienes
    for(int i = 0; i < driversList.length; i++){
      final driverData = driversList[i] as Map?;
      if(driverData == null) continue;

      // Determinar el tipo de vehiculo activo del conductor
      // Esquema nuevo: active_vehicle_type (multi-vehiculo, uno activo a la vez)
      // Esquema legacy: car_details.type
      final driverVehicleType =
          driverData["active_vehicle_type"] ??
          (driverData["car_details"] != null ? driverData["car_details"]["type"] : null);

      final driverToken = driverData["token"];

      if(driverVehicleType == selectedVehicleType && driverToken != null){
        Fluttertoast.showToast(msg: "Notification a user ${i} y es el driver $driverToken");
        AssistantMethods.sendNotificationToDriverNow(
          driverToken,
          referenceRideRequest!.key!,
          context,
          destinationAddress: rideInformationMap["destinationAddress"] ?? '',
        );
      }
    }
    //toast de notificacion enviada
    Fluttertoast.showToast(msg: "Notification sent successfully");

    //
    streamRideRequestStatus = FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).onValue.listen((eventRideRequestSnapshot) async {
        print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");

        if (eventRideRequestSnapshot.snapshot.value == null) {
          // Si el viaje fue eliminado (cancelado o finalizado por el conductor)
          return;
        }

        Map data = eventRideRequestSnapshot.snapshot.value as Map;
        dynamic status = data["status"];
        dynamic fareAmount = data["fareAmount"];
        if(status != null) {
          setState(() => userRideRequestStatus = status.toString());
        }

        if(status == "bidding"){
          dynamic driverOfferedFare = data["driverOfferedFare"];
          String driverName = data["driverName"] ?? "Un conductor";
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => AlertDialog(
              backgroundColor: darkTheme ? Colors.grey[900] : Colors.white,
              title: Text("Oferta Recibida", style: TextStyle(color: darkTheme ? Colors.white : Colors.black)),
              content: Text("$driverName ofrece realizar el viaje por \$${driverOfferedFare}", style: TextStyle(color: darkTheme ? Colors.white : Colors.black)),
              actions: [
                TextButton(
                  onPressed: () {
                    // Rechazar: Vuelve a estado 'waiting' para que otros conductores puedan responder.
                    FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).update({
                      "status": "waiting",
                      "driverId": "-",
                      "driverOfferedFare": null,
                      "driverName": null,
                    });
                    Navigator.pop(context);
                  }, 
                  child: Text("Rechazar", style: TextStyle(color: Colors.red))
                ),
                TextButton(
                  onPressed: () {
                    // Aceptar: Cambia el status a 'accepted', setea el fareAmount y asiga al driverId
                    String driverIdBidding = data["driverIdBidding"] ?? "-";
                    FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).update({
                      "status": "accepted",
                      "fareAmount": driverOfferedFare,
                      "driverId": driverIdBidding,
                    });
                    // También notificamos al conductor específicamente guardando en su propio nodo si es necesario
                    // pero el conductor igual puede escuchar el "All Ride Requests".
                    Navigator.pop(context);
                  }, 
                  child: Text("Aceptar", style: TextStyle(color: Colors.green))
                ),
              ]
            )
          );
        } else if(status == "accepted"){  
          getAssignedDriverInfo();

        } else if(status == "arrived"){
          setState(() => driverRideStatus = "El Chofer ha llegado");
          streamRideRequestDriverLocation!.cancel();
        } else if(status == "ontrip"){
          streamDriverLocationToLeavePassenger();
        }else if(status == 'ended'){
          streamRideRequestDriverLocation!.cancel();
          streamRideRequestStatus!.cancel();
          
          // Obtener fare_amount desde Supabase (fuente autorizada)
          double? fareAmount = await SupabaseService.getFareAmountByFirebaseId(
              referenceRideRequest!.key!);

          // Fallback: intentar leer el valor de Firebase si Supabase aún no lo tiene
          if (fareAmount == null && data['fareAmount'] != null) {
            fareAmount = double.tryParse(data['fareAmount'].toString());
          }

          if (fareAmount == null) {
            Fluttertoast.showToast(msg: "No se pudo obtener el monto del viaje.");
            return;
          }

          String assignedDriverId = data['driverId']?.toString() ?? "";
          String currentRideId = referenceRideRequest!.key!;
          String driverName = data['driverName']?.toString() ?? "";
          String originAddress = data['originAddress']?.toString() ?? "";
          String destinationAddress = data['destinationAddress']?.toString() ?? "";

          // Verificar si el registro ya existe (creado por el conductor)
          bool isSaved = await SupabaseService.isRideSaved(currentRideId);
          
          if (!isSaved) {
            // Si no está guardado, esperamos 2 segundos por si el conductor tiene lag en la red
            await Future.delayed(Duration(seconds: 2));
            isSaved = await SupabaseService.isRideSaved(currentRideId);
          }

          if (isSaved) {
            await Navigator.push(context, MaterialPageRoute(builder: (c)=> TripSummaryScreen(
              assignedDriverId: assignedDriverId,
              rideId: currentRideId,
              driverName: driverName,
              fareAmount: fareAmount,
              originAddress: originAddress,
              destinationAddress: destinationAddress,
            )));
          } else {
            Fluttertoast.showToast(msg: "El viaje finalizó pero no se guardó el registro.");
          }

          referenceRideRequest!.onDisconnect();
          streamRideRequestDriverLocation!.cancel();
          streamRideRequestStatus!.cancel();
          referenceRideRequest!.remove();

          // Esconder la información del conductor y resetear la UI
          resetApp();
        }
    });

  }

  getAssignedDriverInfo() async {

    print("llego a getAssignedDriverInfo");

    dynamic dataSnapshot = await referenceRideRequest!.get();
    Map rideRequestMap = dataSnapshot.value as Map;

    setState(() {
      (rideRequestMap["car_details"] != null)?
      driverCarDetails = rideRequestMap["car_details"].toString():null;

      (rideRequestMap["driverPhone"] != null)?
      driverPhone = rideRequestMap["driverPhone"].toString():null;

      (rideRequestMap["driverName"] != null)?
      driverName = rideRequestMap["driverName"].toString():null;

      (rideRequestMap["ratings"] != null)?
      driverRatings = rideRequestMap["ratings"].toString():null;
    });

    // Consultar la informacion actual del conductor en su nodo de Firebase
    // para que siempre se muestre el vehiculo activo mas reciente y no el
    // que tenia registrado en viajes anteriores.
    String? assignedDriverId = rideRequestMap["driverId"]?.toString();
    if (assignedDriverId != null && assignedDriverId.isNotEmpty && assignedDriverId != "-") {
      await _loadCurrentDriverInfo(assignedDriverId);
    }

    if(rideRequestMap["driverLocation"] != null) {
      double driverCurrentPositionLat = double.parse(rideRequestMap["driverLocation"]["latitude"].toString());
      double driverCurrentPositionLng = double.parse(rideRequestMap["driverLocation"]["longitude"].toString());
      LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);
      updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
      streamDriverLocationToGetPassenger();
    }
    showUIForAssignedDriverInfo();
  }

  Future<void> _loadCurrentDriverInfo(String driverId) async {
    try {
      DatabaseEvent event = await FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(driverId)
          .once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value == null) return;

      Map driverMap = snapshot.value as Map;

      setState(() {
        if (driverMap["names"] != null) driverName = driverMap["names"].toString();
        if (driverMap["phone"] != null) driverPhone = driverMap["phone"].toString();
        if (driverMap["ratings"] != null) driverRatings = driverMap["ratings"].toString();

        // Vehiculo activo actual (esquema multi-vehiculo) o car_details legacy
        final activeVehicle = driverMap["active_vehicle"];
        if (activeVehicle is Map) {
          driverCarDetails = _formatCarDetails(activeVehicle);
        } else if (driverMap["car_details"] is Map) {
          driverCarDetails = _formatCarDetails(driverMap["car_details"] as Map);
        }
      });

      await _loadDriverPhotos(driverId, driverMap);
    } catch (e) {
      log('Error al cargar datos actuales del conductor: $e');
    }
  }

  Widget _driverAvatarPlaceholder(bool darkTheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: darkTheme ? Colors.amber.shade400 : Colors.lightBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.person, color: darkTheme ? Colors.black : Colors.white),
    );
  }

  String _formatCarDetails(Map car) {
    final model = car["car_model"]?.toString() ?? '';
    final number = car["car_number"]?.toString() ?? '';
    final color = car["car_color"]?.toString() ?? '';
    final parts = [model, number, color.isNotEmpty ? '($color)' : '']
        .where((p) => p.isNotEmpty)
        .join(' ');
    return parts.isEmpty
        ? (driverCarDetails.isNotEmpty ? driverCarDetails : "Vehículo")
        : parts;
  }

  Future<void> _loadDriverPhotos(String driverId, Map driverMap) async {
    try {
      String? driverPhoto;
      String? vehiclePhoto;

      // 1) Foto del conductor desde el nodo del conductor en RTDB:
      //    image_url (foto de perfil) o documents.imageSelfie
      final imageUrl = driverMap["image_url"]?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        driverPhoto = imageUrl;
      } else if (driverMap["documents"] is Map) {
        final docs = driverMap["documents"] as Map;
        driverPhoto =
            docs["imageSelfie"]?.toString() ?? docs["imageSelfieWithDocument"]?.toString();
      }

      // 2) Foto del vehiculo activo desde el nodo del conductor en RTDB:
      //    active_vehicle.image o car_details.image
      final activeVehicle = driverMap["active_vehicle"];
      if (activeVehicle is Map) {
        final vehicleImage = activeVehicle["image"]?.toString();
        if (vehicleImage != null && vehicleImage.isNotEmpty) {
          vehiclePhoto = vehicleImage;
        }
      }
      if (vehiclePhoto == null || vehiclePhoto.isEmpty) {
        final carDetails = driverMap["car_details"];
        if (carDetails is Map) {
          final carImage = carDetails["image"]?.toString();
          if (carImage != null && carImage.isNotEmpty) {
            vehiclePhoto = carImage;
          }
        }
      }

      // 3) Fallback: car_documents legacy en el nodo del conductor
      if ((driverPhoto == null || driverPhoto.isEmpty) ||
          (vehiclePhoto == null || vehiclePhoto.isEmpty)) {
        final carDocs = driverMap['car_documents'];
        if (carDocs is Map && carDocs['imageVehicle'] != null) {
          vehiclePhoto ??= carDocs['imageVehicle'].toString();
        }
      }

      // 4) Fallback final: consultar Supabase por si el RTDB aún no tiene
      //    las fotos (conductor con versión anterior de la app).
      if ((driverPhoto == null || driverPhoto.isEmpty) ||
          (vehiclePhoto == null || vehiclePhoto.isEmpty)) {
        final driverRecord = await SupabaseService.client
            .from('drivers')
            .select('image_url, documents, active_vehicle_id')
            .eq('id', driverId)
            .maybeSingle();

        if (driverRecord != null) {
          Map driverInfo = driverRecord as Map;
          if (driverPhoto == null || driverPhoto.isEmpty) {
            final img = driverInfo['image_url']?.toString();
            if (img != null && img.isNotEmpty) {
              driverPhoto = img;
            } else {
              final documents = driverInfo['documents'];
              if (documents is Map && documents['imageSelfie'] != null) {
                driverPhoto = documents['imageSelfie'].toString();
              }
            }
          }

          if (vehiclePhoto == null || vehiclePhoto.isEmpty) {
            String? activeVehicleId = driverInfo['active_vehicle_id']?.toString();
            if (activeVehicleId == null || activeVehicleId.isEmpty) {
              activeVehicleId = driverMap['active_vehicle_id']?.toString();
            }

            if (activeVehicleId != null && activeVehicleId.isNotEmpty) {
              final vehicleRecord = await SupabaseService.client
                  .from('vehicles')
                  .select('documents')
                  .eq('id', activeVehicleId)
                  .maybeSingle();
              if (vehicleRecord != null) {
                Map vehicleInfo = vehicleRecord as Map;
                final docs = vehicleInfo['documents'];
                if (docs is Map && docs['imageVehicle'] != null) {
                  vehiclePhoto = docs['imageVehicle'].toString();
                }
              }
            }
          }
        }
      }

      setState(() {
        driverPhotoUrl = driverPhoto ?? "";
        driverVehiclePhotoUrl = vehiclePhoto ?? "";
      });
    } catch (e) {
      log('Error al cargar fotos del conductor: $e');
    }
  }

  streamDriverLocationToGetPassenger(){
    streamRideRequestDriverLocation = referenceRideRequest!.child("driverLocation").onValue.listen((eventSnap) async{
      if(eventSnap.snapshot.value == null){
        return;
      }
      double driverCurrentPositionLat = double.parse((eventSnap.snapshot.value as Map)["latitude"].toString());
      double driverCurrentPositionLng = double.parse((eventSnap.snapshot.value as Map)["longitude"].toString());

      LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);
      updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
    });
  }

  streamDriverLocationToLeavePassenger(){
    streamRideRequestDriverLocation = referenceRideRequest!.child("driverLocation").onValue.listen((eventSnap) async{
      if(eventSnap.snapshot.value == null){
        return;
      }
      double driverCurrentPositionLat = double.parse((eventSnap.snapshot.value as Map)["latitude"].toString());
      double driverCurrentPositionLng = double.parse((eventSnap.snapshot.value as Map)["longitude"].toString());

      LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);
      updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
    });
  }

  showUIForAssignedDriverInfo(){
    setState((){
      waitingResponseFromDriverContainerHeight = 0;
      searchingForDriverContainerHeight = 0;
      assignedDriverInfoContainerHeight = 210;
      suggestedRidesContainerHeight = 0;
      bottonPaddingOfMap = 200;
    });
  }

  retrieveOnlineDriversInformation(List onlineNearnestDriverList) async {
    driversList.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");

    for(int i = 0; i<onlineNearnestDriverList.length; i++){
      await ref.child(onlineNearnestDriverList[i].driverId.toString()).once().then((dataSnapshot){
        var driverKeyInfo = dataSnapshot.snapshot.value;

        driversList.add(driverKeyInfo);
      });
    }
  }

  updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng) async {
    if(requestPositionInfo == true){
      requestPositionInfo = false;
      LatLng userPickUpPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
          driverCurrentPositionLatLng, userPickUpPosition,
      );

      if(directionDetailsInfo == null){
        return;
      }

      setState(()=>driverRideStatus = "Chofer está en camino: "+directionDetailsInfo.duration_text.toString());

      requestPositionInfo = true;
    }
  }

  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async {
    if(requestPositionInfo == true) {
      requestPositionInfo = false;

      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
    
      LatLng userDestinationPosition = LatLng(
          dropOffLocation!.locationLatitude!,
          dropOffLocation!.locationLongitude!
      );

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
          driverCurrentPositionLatLng,
          userDestinationPosition
      );

      if(directionDetailsInfo == null){
        return;
      }

      setState(()=> driverRideStatus = "Yendo hacia el destino: ${((directionDetailsInfo.duration_value!)/60).toStringAsFixed(0)} minutos");

      requestPositionInfo = true;
    }
  }

  isRouteComplete(){
    var originPosition = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
    return ((originPosition != null)&&( destinationPosition != null));
  }

  initSocket() {
    socket = IO.io("https://venya-backend.onrender.com", <String, dynamic>{
      'autoConnect': false,
      'transports': ['websocket'],
    });
    socket.connect();
    socket.onConnect((_) {
      print('Connection established');
    });
    socket.onDisconnect((_) => print('Connection Disconnection'));
    socket.onConnectError((err) => print(err));
    socket.onError((err) => print(err));
  }

  showSearchingDriverUI(bool darkTheme) {
    print("llego qui");
    if(selectedVehicleType != ""){
      // Validación específica para camión de agua
      if(_vehicleTypeHasExtraFields(selectedVehicleType) && _waterLitersController.text.trim().isEmpty){
        Fluttertoast.showToast(msg: "Por favor, introduce la cantidad \nde litros de agua necesarios");
        return;
      }

      setState(()=> suggestedRidesContainerHeight = 0);
      saveRideRequestInformation(selectedVehicleType, darkTheme);
    } else {
      Fluttertoast.showToast(msg: "por favor selecciona un vehiculo \n de los viajes sugeridos");
    }
  }

  canelRequestRide(){
    setState(() {
      selectedVehicleType='';
      suggestedRidesContainerHeight = 0;
    });
  }

  cancelRideRequestInSearchingForDrive(){
    if (referenceRideRequest != null) {
      referenceRideRequest!.remove();
    }
    
    // Detener los streams si están activos
    if (streamRideRequestStatus != null) {
      streamRideRequestStatus!.cancel().catchError((e) => print('Error cancelando streamStatus: $e'));
      streamRideRequestStatus = null;
    }
    if (streamRideRequestDriverLocation != null) {
      streamRideRequestDriverLocation!.cancel().catchError((e) => print('Error cancelando streamLocation: $e'));
      streamRideRequestDriverLocation = null;
    }

    setState(() {
      selectedVehicleType='';
      searchingForDriverContainerHeight = 0;
      suggestedRidesContainerHeight = 0;
      searchLocationContainerHeight = 220; // Volver a mostrar el contenedor de búsqueda
      bottonPaddingOfMap = 220; // Ajustar padding
      
      // Limpiar datos introducidos
      _fareController.clear();
      _packageController.clear();
      _waterLitersController.clear();
      
      // Limpiar mapa
      polylineSet.clear();
      markerSet.clear();
      circleSet.clear();
      pLineCoordinatedList.clear();
      
      // Reset variables
      driverName = "";
      driverPhone = "";
      driverCarDetails = "";
      driverRatings = "";
      driverPhotoUrl = "";
      driverVehiclePhotoUrl = "";
      driverRideStatus = "Chofer está viniendo";
      userRideRequestStatus = "";
    });

    Fluttertoast.showToast(msg: "Solicitud cancelada");
    
    // Regresar a la posición del usuario
    locateUserPosition();
  }

  cancelRideRequestFromPassenger() {
    referenceRideRequest!.remove();
    
    // Detener los streams
    if (streamRideRequestStatus != null) streamRideRequestStatus!.cancel();
    if (streamRideRequestDriverLocation != null) streamRideRequestDriverLocation!.cancel();
    
    setState(() {
      assignedDriverInfoContainerHeight = 0;
      searchLocationContainerHeight = 220;
      bottonPaddingOfMap = 0;
      
      // Limpiar mapa
      polylineSet.clear();
      markerSet.clear();
      circleSet.clear();
      pLineCoordinatedList.clear();
      
      // Reset variables
      driverName = "";
      driverPhone = "";
      driverCarDetails = "";
      driverRatings = "";
      driverPhotoUrl = "";
      driverVehiclePhotoUrl = "";
      driverRideStatus = "Chofer está viniendo";
      userRideRequestStatus = "";
    });

    Fluttertoast.showToast(msg: "Has cancelado el viaje.");
    
    // Regresar a la posición del usuario
    locateUserPosition();
  }

  void resetApp() {
  setState(() {
    // Ocultar la información del conductor (altura del contenedor)
    assignedDriverInfoContainerHeight = 0;
    
    // Resetear el estado del mapa
    selectedVehicleType = '';
    pLineCoordinatedList.clear();
    polylineSet.clear();
    markerSet.clear();
    circleSet.clear();

    bottonPaddingOfMap = 0;
    
    // Resetear variables de datos
    driverName = "";
    driverPhone = "";
    driverCarDetails = "";
    driverRatings = "";
    driverPhotoUrl = "";
    driverVehiclePhotoUrl = "";
    driverRideStatus = "Chofer está viniendo";
    userRideRequestStatus = "";
    _fareHourMultipliers = [];
    _vehicleTypes = null;
    
    // Limpiar los controladores de texto
    _fareController.clear();
    _packageController.clear();
    
    // Detener listeners si están activos
    // (Esto se maneja mejor en un bloque try/catch o con guards, pero por ahora aseguramos que los streams no cause errores si se intenta cancelar)
  });
  
  // Cancelar streams pendientes
  if (streamRideRequestStatus != null) {
    streamRideRequestStatus!.cancel().catchError((e) => print('Error cancelando streamStatus: $e'));
    streamRideRequestStatus = null;
  }
  if (streamRideRequestDriverLocation != null) {
    streamRideRequestDriverLocation!.cancel().catchError((e) => print('Error cancelando streamLocation: $e'));
    streamRideRequestDriverLocation = null;
  }
  
  // Re-iniciar la búsqueda de la posición del usuario
  locateUserPosition();
}

  @override
  void initState(){
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  @override
  void dispose() {
    _fareController.dispose();
    _packageController.dispose();
    _waterLitersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    createActiveNearByDriverIconMarker();

    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: _scafforState,
        drawer: DrawerScreen(),
        body: Stack(
          children: [
            GoogleMap(
                mapType: MapType.normal,
                myLocationEnabled: true,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: true,
                initialCameraPosition: _kGooglePlex,
                polylines: polylineSet,
                markers: markerSet,
                circles: circleSet,
                onMapCreated: (GoogleMapController controller){
                  _controllerGoogleMap.complete(controller);
                  newGoogleMapController = controller;

                  if(darkTheme == true){
                    setState(() {
                      blackThemeGoogleMapI(newGoogleMapController);
                    });
                  }

                  locateUserPosition();
                },
            ),
            //custom hamburger button for drawer
            Positioned(
                top: 50,
                left: 20,
                child: Container(
                  child: GestureDetector(
                    onTap: (){
                      _scafforState.currentState!.openDrawer();
                    },
                    child: CircleAvatar(
                      backgroundColor: darkTheme ? Colors.amber.shade400: Colors.white,
                      child: Icon(
                        Icons.menu,
                        color: darkTheme ? Colors.black: Colors.lightBlue,
                      ),
                    ),
                  ),
                )
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 50, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: darkTheme ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: darkTheme? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Column(
                              children: [

                                Padding(
                                    padding: EdgeInsets.all(5),
                                    child: GestureDetector(
                                      onTap: () async {
                                        //go to search places screen
                                        var responseFromSearch = await Navigator.push(context, MaterialPageRoute(builder: (c)=> PrecisePickUpLocationScreen()));

                                        if(responseFromSearch == 'obtainedDropoff'){
                                          setState(()=>openNavigatorDrawer = false);
                                        }
                                        if(isRouteComplete()){
                                          await drawPolyLineFromOriginToDestination(darkTheme);
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.my_location, color: Colors.green),
                                          SizedBox(width: 10,),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Desde",
                                                style: TextStyle(
                                                  color: darkTheme? Colors.amber.shade400: Colors.blue,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold
                                                )
                                              ),
                                              Text(
                                                displayLocationString(Provider.of<AppInfo>(context).userPickUpLocation),
                                                style: TextStyle(color: Colors.grey, fontSize: 14),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                ),
                                SizedBox(height: 5,),
                                Divider(
                                  height: 1,
                                  thickness: 2,
                                  color: darkTheme? Colors.amber.shade400: Colors.blue,
                                ),
                                SizedBox(height: 5,),
                                Padding(
                                  padding: EdgeInsets.all(5),
                                  child: GestureDetector(
                                    onTap: () async {
                                      //go to search places screen
                                      var responseFromSearch = await Navigator.push(context, MaterialPageRoute(builder: (c)=> PreciseDropOffLocationScreen()));

                                      if(responseFromSearch == 'obtainedDropoff'){
                                        setState(()=>openNavigatorDrawer = false);
                                      }
                                      if(isRouteComplete()){
                                        await drawPolyLineFromOriginToDestination(darkTheme);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.red),
                                        SizedBox(width: 10,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Hasta donde",
                                                style: TextStyle(
                                                    color: darkTheme? Colors.amber.shade400: Colors.blue,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold
                                                )
                                            ),
                                            Text(
                                              displayLocationString(Provider.of<AppInfo>(context).userDropOffLocation),
                                              style: TextStyle(color: Colors.grey, fontSize: 14),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 5,),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                    if(isRouteComplete()){
                                      await showSuggestedRidesContainer();
                                    }else{
                                      Fluttertoast.showToast(msg: "Por favor seleccionar \n ubicación de destino");
                                    }
                                },
                                child: Text(
                                  "Mostrar Tarifas",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: darkTheme?
                                                        isRouteComplete()? Colors.amber.shade400:Colors.amber.shade100
                                                      :
                                                        isRouteComplete()? Colors.blue:Colors.blue.shade100,
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    )
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    )
                  ],
                ),
              ),
            ),

            //Selecting type of car
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: suggestedRidesContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme? Colors.black: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  )
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: darkTheme? Colors.amber.shade400 : Colors.blue,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.white,
                                    ),
                                  ),

                                  SizedBox(width: 15,),

                                  Text(displayLocationString(Provider.of<AppInfo>(context).userPickUpLocation),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),

                                ],
                              ),

                              SizedBox(height: 20,),

                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 15,),
                                  Text(
                                    displayLocationString(Provider.of<AppInfo>(context).userDropOffLocation),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),

                                ],
                              ),

                              const SizedBox(height: 20,),
                              const Text("VIAJES SUGERIDOS", style: TextStyle(fontWeight: FontWeight.bold),),
                              const SizedBox(height: 20,),

                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: _buildVehicleTypeCards(darkTheme),
                                ),
                              ),


                              const SizedBox(height: 16),

                              if (!(_getSelectedVehicleTypeObj()?.hasCustomFare ?? false) && !_vehicleTypeHasExtraFields(selectedVehicleType))
                                Column(
                                  children: [
                                    // ── Detalles de Encomienda (Opcional) ──────────────────────────
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _packageController,
                                            decoration: InputDecoration(
                                              hintText: '¿Qué envías? (Encomienda opcional)',
                                              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),

                              if(_vehicleTypeHasExtraFields(selectedVehicleType))
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.water_drop_outlined,
                                          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _waterLitersController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                              hintText: 'Cantidad de Litros de Agua solicitados',
                                              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),

                              // ── Oferta de tarifa opcional ──────────────────────────
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _fareController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        hintText: tripDirectionDetailsInfo != null
                                            ? 'Estimado: \$ $estimatedFare - o ingresa tu oferta'
                                            : 'Tu oferta de tarifa (opcional)',
                                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                                        prefixText: '\$ ',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: GestureDetector(
                            onTap: (){
                              print("darkTheme: $darkTheme");
                              showSearchingDriverUI(darkTheme);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: darkTheme ? Colors.amber.shade400:Colors.blue,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: Center(
                                child: Text(
                                    "Solicitar",
                                    style: TextStyle(
                                      color: darkTheme? Colors.black: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    )
                                ),
                              ),
                            ),
                          )),
                          SizedBox(width: 10,),
                          Expanded(child: GestureDetector(
                            onTap: ()=>cancelRideRequestInSearchingForDrive(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: Center(
                                child: Text(
                                    "Cancelar",
                                    style: TextStyle(
                                      color: darkTheme? Colors.black: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    )
                                ),
                              ),
                            ),
                          ))
                        ],
                      )

                    ],
                  )
                ),
              )
            ),
            

            //Requesting  a ride or waiting
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: searchingForDriverContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme? Colors.black : Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                      SizedBox(height: 10,),
                      Center(
                        child: Text(
                          "Buscando Conductor",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,

                          ),
                        ),
                      ),

                      SizedBox(height: 20,),

                      GestureDetector(
                        onTap: ()=>cancelRideRequestInSearchingForDrive(),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: darkTheme?Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(width: 1, color: Colors.grey),
                          ),
                          child: Icon(Icons.close, size: 25,),
                        ),
                      ),

                      SizedBox(height: 15,),

                      Container(
                        width: double.infinity,
                        child: Text(
                          "Cancelar",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            //Ui de para mostrar la informacion del usuario
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: assignedDriverInfoContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(driverRideStatus, style: TextStyle(fontWeight: FontWeight.bold, color: darkTheme ? Colors.white : Colors.black)),
                      SizedBox(height: 5),
                      Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                      SizedBox(height: 5),

                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:[
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: driverPhotoUrl.isNotEmpty
                                    ? Image.network(
                                        driverPhotoUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => _driverAvatarPlaceholder(darkTheme),
                                      )
                                    : _driverAvatarPlaceholder(darkTheme),
                              ),
                              SizedBox(width: 10,),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:[
                                    Text(driverName,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: darkTheme ? Colors.white : Colors.black)
                                    ),
                                    Row(
                                        children:[
                                          Icon(Icons.star, color: Colors.orange),

                                          SizedBox(width: 5),

                                          Text(driverRatings.isNotEmpty ? driverRatings : "0.00",
                                              style: TextStyle(
                                                  color: darkTheme ? Colors.white : Colors.black
                                              )
                                          )
                                        ]
                                    )
                                  ]
                              ),
                            ],
                          ),
                          SizedBox(width: 30,),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children:[
                              driverVehiclePhotoUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        driverVehiclePhotoUrl,
                                        width: 64,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Image.asset("images/car.png", scale: 10),
                                      ),
                                    )
                                  : Image.asset("images/car.png", scale: 10,),

                              SizedBox(height: 3,),

                              Text(driverCarDetails, style: TextStyle(fontSize: 12, color: darkTheme ? Colors.white : Colors.black), )
                              
                            ]
                          ),
                        ]
                      ),

                      SizedBox(height: 5),
                      Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _makePhoneCall("tel: ${driverPhone}");
                            },
                            style:ElevatedButton.styleFrom(backgroundColor: darkTheme? Colors.amber.shade400: Colors.blue),
                            icon: Icon(Icons.phone),
                            label: Text("LLamar al conductor", style: TextStyle(fontSize: 12),),
                          ),
                          if (userRideRequestStatus == "accepted" || userRideRequestStatus == "arrived")
                            Row( children:[

                              const SizedBox(width: 5),

                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) => AlertDialog(
                                        title: const Text("Cancelar Viaje"),
                                        content: const Text("¿Estás seguro de que deseas cancelar este viaje?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text("No"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              cancelRideRequestFromPassenger();
                                            },
                                            child: const Text("Sí, Cancelar", style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  icon: const Icon(Icons.cancel, color: Colors.white),
                                  label: const Text("Cancelar Viaje", style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          )
                        ]
                      )
                    ]
                  )

                )
              )
            )


          ],
        ),
      ),
    );
  }
}


