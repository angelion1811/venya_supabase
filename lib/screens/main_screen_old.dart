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

Future<void> _makePhoneCall(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}

class MainScreenOld extends StatefulWidget {
  const MainScreenOld({Key? key}) : super(key: key);

  @override
  State<MainScreenOld> createState() => _MainScreenOldState();
}

class _MainScreenOldState extends State<MainScreenOld> {

  LatLng? pickLocation;
  loc.Location location = loc.Location();
  String? _address;


  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;


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

  String driverRideStatus = "Driver is coming";
  StreamSubscription<DatabaseEvent>? tripRideRequestInfoStreamSubscription;

  List<ActiveNearByAvailableDrivers> onlineNearByAvailableDriversList = [];

  String userRideRequestStatus = "";

  bool requestPositionInfo = true;




  locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng latLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 15);

    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    initializeGeoFireListener();


    String humaneReableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(userCurrentPosition!.latitude, userCurrentPosition!.longitude, context);
    print("this is our address = "+humaneReableAddress);

    userName = userModelCurrentInfo!.name!;
    useEmail = userModelCurrentInfo!.email!;

    //
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

      setState(() {

      });
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

      setState(() {
        markerSet = driversMarkerSet;
      });

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

    setState(() {
      tripDirectionDetailsInfo =  directionDetailsInfo;
    });

    Navigator.pop(context);

    /*
    PolylinePoints pPOints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResultList = pPOints.decodePolyline(directionDetailsInfo.e_points!);

    pLineCoordinatedList.clear();

    if(decodePolylinePointsResultList.isNotEmpty){
      decodePolylinePointsResultList.forEach((PointLatLng pointLatLng) {
        pLineCoordinatedList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    */
    pLineCoordinatedList.clear();

    if(directionDetailsInfo.e_points!.isNotEmpty){
        var list = directionDetailsInfo.e_points;
        for(int i=0; i< list.length; i++){
          pLineCoordinatedList.add(LatLng(list[i][1], list[i][0]));
        }
    }
    setState(() {
      polylineSet.clear();
    });

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
    setState(()=>searchingForDriverContainerHeight = 200);
  }

  void showSuggestedRidesContainer(){
    setState(() {
      suggestedRidesContainerHeight = 400;
      bottonPaddingOfMap = 400;
    });
  }
  /*
  getAddressFromLatlng() async {
    try {
      GeoData data = await Geocoder2.getDataFromCoordinates(
          latitude: pickLocation!.latitude,
          longitude: pickLocation!.longitude,
          googleMapApiKey: mapKey
      );
      setState(() {
        Directions userPickUpAddress = Directions();
        userPickUpAddress.locationLatitude = pickLocation!.latitude;
        userPickUpAddress.locationLongitude = pickLocation!.longitude;
        userPickUpAddress.locationName = data.address;
        //_address = data.address;
        Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);
      });
    } catch(e) {
      print(e);
    }
  }
   */

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();

    if(_locationPermission == LocationPermission.denied){
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  saveRideRequestInformation(String selectedVehicleType){
    referenceRideRequest = FirebaseDatabase.instance.ref().child("All Ride Requests").push();

    var originLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map originLocationMap = {
      //"key": value"
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };

    Map destinationLocationMap = {
      //"key": value"
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };

    Map userInformationMap = {
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time":DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name,
      "userPhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locationName,
      "destinationAddress": destinationLocation.locationName,
      "driverId":"waiting",
    };

    referenceRideRequest!.set(userInformationMap);

    tripRideRequestInfoStreamSubscription = referenceRideRequest!.onValue.listen((eventSnap) async{
      if(eventSnap.snapshot.value == null){
        return;
      }

      if((eventSnap.snapshot.value as Map)["car_details"] != null){
        setState(() {
          driverCarDetails = (eventSnap.snapshot.value as Map)["car_details"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverPhone"] != null){
        setState(() {
          driverPhone = (eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverName"] != null){
        setState(() {
          driverName = (eventSnap.snapshot.value as Map)["driverName"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["ratings"] != null){
        setState(() {
          driverRatings = (eventSnap.snapshot.value as Map)["ratings"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["status"] != null){
        setState(() {
          userRideRequestStatus = (eventSnap.snapshot.value as Map)["status"].toString();
        });
        print("userRideRequestStatus");
        print(userRideRequestStatus);
      }

      if((eventSnap.snapshot.value as Map)["driverLocation"] != null){
        double driverCurrentPositionLat = double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["latitude"].toString());
        double driverCurrentPositionLng = double.parse((eventSnap.snapshot.value as Map)["driverLocation"]["longitude"].toString());

        LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);

        //status = acepted
        if(userRideRequestStatus == "accepted"){
          updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
        }
        //status = arrived
        if(userRideRequestStatus == "arrived"){
          setState(() {
            driverRideStatus = "El Chofer ha llegado";
          });
        }
        //status = on trip
        if(userRideRequestStatus == "ontrip"){
          updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
        }
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

                referenceRideRequest!.onDisconnect();
                tripRideRequestInfoStreamSubscription!.cancel();
              }
            }
          }
        }
      }
    });
    onlineNearByAvailableDriversList = GeoFireAssistant.activeNearByAvailableDriversList;
    searchNearestOnlineDrivers(selectedVehicleType);
  }

  searchNearestOnlineDrivers(String selectedVehicleType) async {
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
    await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

    for(int i = 0; i < driversList.length; i++){
      if(driversList[i]["car_details"]["type"] == selectedVehicleType){
        print("va a llamar a token:");
        print(driversList[i]["token"]);
        print("referenceRideRequest!.key!:");
        print(referenceRideRequest!.key!);
        AssistantMethods.sendNotificationToDriverNow(driversList[i]["token"], referenceRideRequest!.key!, context);
      }
    }

    Fluttertoast.showToast(msg: "Notification sent successfully");

    showUISearchingForDriversContainer();
    
    await FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).child("driverId").onValue.listen((eventRideRequestSnapshot) {
        print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");
        if(eventRideRequestSnapshot.snapshot.value != "waiting"){
          showUIForAssignedDriverInfo();
        }
    });

  }

  showUIForAssignedDriverInfo(){
    setState((){
      waitingResponseFromDriverContainerHeight = 0;
      searchingForDriverContainerHeight = 0;
      assignedDriverInfoContainerHeight = 200;
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

      setState(() {
        driverRideStatus = "Chofer está en camino: "+directionDetailsInfo.duration_text.toString();
      });

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

      setState(() {
        driverRideStatus = "Yendo hacia el destino: "+directionDetailsInfo.duration_text.toString();
      });

      requestPositionInfo = true;
    }
  }



  @override
  void initState(){
    super.initState();
    checkIfLocationPermissionAllowed();
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
                                        setState(() {
                                          openNavigatorDrawer = false;
                                        });
                                      }

                                      await drawPolyLineFromOriginToDestination(darkTheme);
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
                                    Navigator.push(context, MaterialPageRoute(builder: (c)=> PrecisePickUpLocationScreen()));
                                  },
                                  child: Text(
                                    "Cambiar dirección \n de recogida",
                                    style: TextStyle(
                                      color: darkTheme ? Colors.black: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: darkTheme? Colors.amber.shade400: Colors.blue,
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    )
                                  ),
                              ),
                              SizedBox(width: 10,),
                              ElevatedButton(
                                onPressed: (){
                                    if(Provider.of<AppInfo>(context, listen: false).userDropOffLocation != null){
                                      showSuggestedRidesContainer();
                                    } else {
                                      Fluttertoast.showToast(msg: "Por favor seleccionar \n ubicación de destino");
                                    }
                                    showSuggestedRidesContainer();

                                },
                                child: Text(
                                  "Mostrar Tarifas",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: darkTheme? Colors.amber.shade400: Colors.blue,
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
                            SizedBox(width: 15,),
                            Text(
                              displayLocationString(Provider.of<AppInfo>(context).userDropOffLocation),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                          ],
                        ),

                        SizedBox(height: 20,),

                        Text("VIAJES SUGERIDOS", style: TextStyle(fontWeight: FontWeight.bold),),

                        SizedBox(height: 20,),

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
                              onTap: (){
                                setState(() {
                                  selectedVehicleType = "Car";
                                });
                              },
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
                              onTap: (){
                                setState(() {
                                  selectedVehicleType = "CNG";
                                });
                              },
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
                              onTap: (){
                                setState(() {
                                  selectedVehicleType = "Bike";
                                });
                              },
                            )
                          ],
                        ),

                        SizedBox(height: 20,),

                        Expanded(child: GestureDetector(
                          onTap: (){
                            if(selectedVehicleType != ""){
                              saveRideRequestInformation(selectedVehicleType);
                            } else {
                              Fluttertoast.showToast(msg: "por favor selecciona un vehiculo \n de los viajes sugeridos");
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.amber.shade400:Colors.blue,
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Center(
                              child: Text(
                                "Solicitar viaje",
                                style: TextStyle(
                                  color: darkTheme? Colors.black: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                )
                              ),
                            ),
                          ),
                        ))
                      ],
                    )
                  ),
                )
            ),

            //Requesting  a ride
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
                        onTap: (){
                          referenceRideRequest!.remove();
                          setState(() {
                            searchingForDriverContainerHeight = 0;
                            suggestedRidesContainerHeight = 0;
                          });
                        },
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:[
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.amber.shade400: Colors.lightBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.person, color: darkTheme ? Colors.black : Colors.white),
                          ),

                          SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:[
                              Text(driverName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                              Row(
                                children:[
                                  Icon(Icons.star, color: Colors.orange),

                                  SizedBox(width: 5),

                                  Text( driverRatings??"0.00",
                                    style: TextStyle(
                                      color: Colors.grey
                                    )
                                  )

                                ]
                              )
                            ]
                          ),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children:[
                              Image.asset("images/car.png", scale: 10,),

                              Text(driverCarDetails, style: TextStyle(fontSize: 12), )
                              
                            ]
                          ),
                          ])


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


