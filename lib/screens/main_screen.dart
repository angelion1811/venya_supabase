import 'dart:async';
import 'dart:developer';
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
import 'package:ven_app/screens/rate_driver_screen.dart';
import 'package:ven_app/splashScreen/splash_screen.dart';
import 'package:ven_app/widgets/card_vehicle_type.dart';
import 'package:ven_app/widgets/progress_dialog.dart';
import '../Assistants/black_theme_google_map.dart';
import '../widgets/pay_fare_amount_dialog.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../Assistants/socket_assistant.dart';

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


  locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;
    LatLng latLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 15);
    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    initializeGeoFireListener();
    String humaneReableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(userCurrentPosition!.latitude, userCurrentPosition!.longitude, context);
    print("this is our address = "+humaneReableAddress);
    userName = userModelCurrentInfo!.names!;
    useEmail = userModelCurrentInfo!.email!;
    AssistantMethods.readTripsKeysForOnlineUser(context);
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
    setState(()=>tripDirectionDetailsInfo =  directionDetailsInfo);

    Navigator.pop(context);

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

  void showSuggestedRidesContainer(){
    setState(() {
      suggestedRidesContainerHeight = 550;
      bottonPaddingOfMap = 550;
    });
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();

    if(_locationPermission == LocationPermission.denied){
      _locationPermission = await Geolocator.requestPermission();
    } else {
      locateUserPosition();
    }
  }

  saveRideRequestInformation(String selectedVehicleType){
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
      "estimatedFare": estimatedFare, // tarifa estimada por el sistema
      "packageDetails": packageDetails, // detalles de la encomienda
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
    searchNearestOnlineDrivers(selectedVehicleType, rideInformationMap);
  }

  searchNearestOnlineDrivers(String selectedVehicleType, Map<String, dynamic> rideInformationMap) async {
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
      if(driversList[i]["car_details"]["type"] == selectedVehicleType && driversList[i]["token"] != null){
        Fluttertoast.showToast(msg: "Notification a user ${i} y es el driver ${driversList[i]["token"]}");
        AssistantMethods.sendNotificationToDriverNow(
          driversList[i]["token"],
          referenceRideRequest!.key!,
          context,
          destinationAddress: rideInformationMap["destinationAddress"] ?? '',
        );
      }
    }
    //toast de notificacion enviada
    Fluttertoast.showToast(msg: "Notification sent successfully");

    //
    streamRideRequestStatus = FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).child("status").onValue.listen((eventRideRequestSnapshot) async {
        print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");

        dynamic status = eventRideRequestSnapshot.snapshot.value;
        if(status == "accepted"){
          getAssignedDriverInfo();

        } else if(status == "arrived"){
          setState(() => driverRideStatus = "El Chofer ha llegado");
          streamRideRequestDriverLocation!.cancel();
        } else if(status == "ontrip"){
          streamDriverLocationToLeavePassenger();
        }else if(status == 'ended'){
          streamRideRequestDriverLocation!.cancel();
          streamRideRequestStatus!.cancel();
          dynamic fareAmountRef = await referenceRideRequest!.child('fareAmount').get();
          double fareAmount = double.parse(fareAmountRef.value);

          var response = await showDialog(
              context: context,
              builder: (BuildContext context) => PayFareAmountDialog(
                fareAmount: fareAmount,
              )
          );

          if(response == "Cash Paid"){
            //user can rate the driver now
            dynamic driverId = await referenceRideRequest!.child('driverId').get();
            String assignedDriverId = driverId.value;

            Navigator.push(context, MaterialPageRoute(builder: (c)=> RateDriverScreen(
              assignedDriverId: assignedDriverId,
            )));

            rideInformationMap['_id'] = referenceRideRequest!.key;
            var responseRequest = await SupabaseService.saveRide(rideInformationMap);
            referenceRideRequest!.onDisconnect();
            streamRideRequestDriverLocation!.cancel();
            streamRideRequestStatus!.cancel();
            referenceRideRequest!.remove();
          }
        }
    });

  }

  getAssignedDriverInfo() async {

    print("llego a getAssignedDriverInfo");

    dynamic dataSnapshot = await referenceRideRequest!.get();
    (dataSnapshot.value as Map)["car_details"] != null?
    setState(()=>driverCarDetails = (dataSnapshot.value as Map)["car_details"].toString()):null;

    (dataSnapshot.value as Map)["driverPhone"] != null?
    setState(()=>driverPhone = (dataSnapshot.value as Map)["driverPhone"].toString()):null;

    (dataSnapshot.value as Map)["driverName"] != null?
    setState(()=> driverName = (dataSnapshot.value as Map)["driverName"].toString()):null;

    (dataSnapshot.value as Map)["ratings"] != null?
    setState(()=> driverRatings = (dataSnapshot.snapshot.value as Map)["ratings"].toString()):null;

    if((dataSnapshot.value as Map)["driverLocation"] != null) {
      double driverCurrentPositionLat = double.parse((dataSnapshot.value as Map)["driverLocation"]["latitude"].toString());
      double driverCurrentPositionLng = double.parse((dataSnapshot.value as Map)["driverLocation"]["longitude"].toString());
      LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);
      updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
      streamDriverLocationToGetPassenger();
    }
    showUIForAssignedDriverInfo();
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

  showSearchingDriverUI() {
    print("llego qui");
    if(selectedVehicleType != ""){
      setState(()=> suggestedRidesContainerHeight = 0);
      saveRideRequestInformation(selectedVehicleType);
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
    referenceRideRequest!.remove();
    setState(() {
      selectedVehicleType='';
      searchingForDriverContainerHeight = 0;
      suggestedRidesContainerHeight = 0;
      _fareController.clear();
      _packageController.clear();
    });
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
                                        Icon(Icons.location_on_outlined, color: darkTheme? Colors.amber.shade400: Colors.blue ),
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
//                                      var responseFromSearch = await Navigator.push(context, MaterialPageRoute(builder: (c)=> SearchPlacesScreen()));
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
                                        Icon(Icons.location_on_outlined, color: darkTheme? Colors.amber.shade400: Colors.blue ),
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
                                onPressed: (){
                                    if(isRouteComplete()){
                                      showSuggestedRidesContainer();
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

                          ],)
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
                    child:Column(
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

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CardVehicleType(
                              darkTheme: darkTheme,
                              assetImageString: "images/car.png",
                              assetImageScale: 9,
                              selectedVehicleType: selectedVehicleType,
                              vehicleType: "Car",
                              vehicleTypeString: "Carro",
                              amountString:tripDirectionDetailsInfo != null?'\$ ${((AssistantMethods.calculateFareAroundFromOriginToDestination(tripDirectionDetailsInfo!) * 2)*1)}'
                                  : "",
                              onTap: ()=>setState((){
                                selectedVehicleType = "Car";
                                estimatedFare ='${((AssistantMethods.calculateFareAroundFromOriginToDestination(tripDirectionDetailsInfo!) * 2)*1).toStringAsFixed(2)}';
                                }),
                            ),
                            const SizedBox(width: 5,),
                            CardVehicleType(
                              darkTheme: darkTheme,
                              assetImageString: "images/CNG.png",
                              assetImageScale: 4,
                              selectedVehicleType: selectedVehicleType,
                              vehicleType: "CNG",
                              vehicleTypeString: "CNG",
                              amountString:tripDirectionDetailsInfo != null?'\$ ${((AssistantMethods.calculateFareAroundFromOriginToDestination(tripDirectionDetailsInfo!) * 1.5)*1).toStringAsFixed(2)}'
                                  : "",
                              onTap: ()=>setState((){
                                selectedVehicleType = "CNG";
                                estimatedFare ='${((AssistantMethods.calculateFareAroundFromOriginToDestination(tripDirectionDetailsInfo!) * 1.5)*1).toStringAsFixed(2)}';
                                }),
                            ),
                            const SizedBox(width: 5,),
                            CardVehicleType(
                              darkTheme: darkTheme,
                              assetImageString: "images/Bike.png",
                              assetImageScale: 9,
                              selectedVehicleType: selectedVehicleType,
                              vehicleType: "Bike",
                              vehicleTypeString: "Moto",
                              amountString:tripDirectionDetailsInfo != null?'\$ ${((AssistantMethods.calculateFareAroundFromOriginToDestination(tripDirectionDetailsInfo!) * 1)*1).toStringAsFixed(2)}'
                                  : "",
                              onTap: ()=>setState((){
                                selectedVehicleType = "Bike";
                                estimatedFare ='${((AssistantMethods.calculateFareAroundFromOriginToDestination(tripDirectionDetailsInfo!) * 1)*1).toStringAsFixed(2)}';
                                }),
                            )
                          ],
                        ),

                        const SizedBox(height: 16),

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

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: GestureDetector(
                              onTap: ()=>showSearchingDriverUI(),
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
                      Text(driverRideStatus, style: TextStyle(fontWeight: FontWeight.bold,)),
                      SizedBox(height: 5),
                      Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                      SizedBox(height: 5),

                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:[
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: darkTheme ? Colors.amber.shade400: Colors.lightBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.person, color: darkTheme ? Colors.black : Colors.white),
                              ),
                              SizedBox(width: 10,),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:[
                                    Text(driverName,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
                                    ),
                                    Row(
                                        children:[
                                          Icon(Icons.star, color: Colors.orange),

                                          SizedBox(width: 5),

                                          Text("0.00",
                                              style: TextStyle(
                                                  color: Colors.black
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
                              Image.asset("images/car.png", scale: 10,),

                              Text(driverCarDetails, style: TextStyle(fontSize: 12), )
                              
                            ]
                          ),
                        ]
                      ),

                      SizedBox(height: 5),
                      Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                      ElevatedButton.icon(
                        onPressed: () {
                          _makePhoneCall("tel: ${driverPhone}");
                        },
                        style:ElevatedButton.styleFrom(backgroundColor: darkTheme? Colors.amber.shade400: Colors.blue),
                        icon: Icon(Icons.phone),
                        label: Text("LLamar al conductor"),
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


