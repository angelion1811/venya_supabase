import 'dart:async';
import 'dart:developer';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/Assistants/assistant_methods.dart';
import 'package:ven_app/Assistants/geofire_assistant.dart';
import 'package:ven_app/Helpers/custom_functions.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/global/map_key.dart';
import 'package:ven_app/infoHandler/app_info.dart';
import 'package:ven_app/models/active_nearby_available_drivers.dart';
import 'package:ven_app/screens/drawer_screen.dart';
import 'package:ven_app/screens/precise_pickup_location.dart';
import 'package:ven_app/screens/search_places_screen.dart';
import 'package:ven_app/splashScreen/splash_screen.dart';
import 'package:ven_app/widgets/card_vehicle_type.dart';
import 'package:ven_app/widgets/progress_dialog.dart';
import '../models/directions.dart';
import '../widgets/pay_fare_amount_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

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
/*
    userName = userModelCurrentInfo!.name!;
    useEmail = userModelCurrentInfo!.email!;
    */
    //
    //AssistantMethods.readTripsKeysForOnlineUser(context);

  }

  initializeGeoFireListener(){
    Geofire.initialize("activeDrivers");
    Geofire.queryAtLocation(userCurrentPosition!.latitude, userCurrentPosition!.longitude, 10)!.listen((map) {
      print(map);
      if(map != null){
        var callBack = map["callBack"];

        switch(callBack){
        // whenever any driver become active/online
          case Geofire.onKeyEntered:
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
    log("createActiveNearByDriverIconMarker");
    log(activeNearbyIcon.toString());
    if(activeNearbyIcon == null){
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(1,1));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car3.png").then((value){
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

  void showSearchingForDriversContainer(){
    setState(() {
      searchingForDriverContainerHeight = 200;
    });
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
    var destinationLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;

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
          driverCarDetails = (eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["driverName"] != null){
        setState(() {
          driverCarDetails = (eventSnap.snapshot.value as Map)["driverName"].toString();
        });
      }

      if((eventSnap.snapshot.value as Map)["status"] != null){
        setState(() {
          userRideRequestStatus = (eventSnap.snapshot.value as Map)["status"].toString();
        });
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
            driverRideStatus = "Driver has arrived";
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
                //Navigator.push(context, MaterialPageRoute(builder: (c)=> RateDriverScreen()));

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

      Fluttertoast.showToast(msg: "No Online nearest Driver Available");
      Fluttertoast.showToast(msg: "Searcher Argain. \n Restarting App");

      Future.delayed(Duration(milliseconds: 4000), (){
        referenceRideRequest!.remove();
        Navigator.push(context, MaterialPageRoute(builder: (c)=> SplashScreen()));
      });
      return;
    }
    await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

    print("Driver list: "+driversList.toString());

    for(int i = 0; i < driversList.length; i++){
      if(driversList[i]["car_details"]["type"] == selectedVehicleType){
        AssistantMethods.sendNotificationToDriverNow(driversList[i]["token"], referenceRideRequest!.key!, context);

      }
    }

    Fluttertoast.showToast(msg: "Notification sent successfully");

    showSearchingForDriversContainer();
    
    await FirebaseDatabase.instance.ref().child("All Ride Requests").child(referenceRideRequest!.key!).child("driverId").onValue.listen((eventRideRequestSnapshot) {
        print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");
        if(eventRideRequestSnapshot.snapshot.value != "waiting"){
          showUIForAssignedDriverInfo();
        }
    });

  }

  showUIForAssignedDriverInfo(){
    setState(() {
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
        print("driver key information"+driversList.toString());
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
        driverRideStatus = "Driver is coming: "+directionDetailsInfo.duration_text.toString();
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
        driverRideStatus = "Going towards Destination"+directionDetailsInfo.duration_text.toString();
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

                  setState(() {

                  });

                  locateUserPosition();
                },
              /*
                onCameraMove:(CameraPosition? position){
                  if(pickLocation != position!.target){
                    setState(() {
                      pickLocation = position.target;
                    });
                  }
                },
                onCameraIdle: () {
                  getAddressFromLatlng();
                },
               */
            ),
            /*
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35.0),
                child: Image.asset('images/pick.png', height: 45, width: 45,),
              ),
            ),
             */
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
                                      var responseFromSearch = await Navigator.push(context, MaterialPageRoute(builder: (c)=> SearchPlacesScreen()));

                                      if(responseFromSearch == 'obtainedDropoff'){
                                        print("llegamos aca");
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
                                    Navigator.push(context, MaterialPageRoute(builder: (c)=> PrecisePickUpScreen()));
                                  },
                                  child: Text(
                                    "Change pick up Address",
                                    style: TextStyle(
                                      color: darkTheme ? Colors.black: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    primary: darkTheme? Colors.amber.shade400: Colors.blue,
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
                                      Fluttertoast.showToast(msg: "Please select destination location");
                                    }
                                    showSuggestedRidesContainer();

                                },
                                child: Text(
                                  "Show fare",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                    primary: darkTheme? Colors.amber.shade400: Colors.blue,
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

                        Text("SUGGESTED RIDES", style: TextStyle(fontWeight: FontWeight.bold),),

                        SizedBox(height: 20,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CardVehicleType(
                              darkTheme: darkTheme,
                              assetImageString: "images/car5.png",
                              assetImageScale: 9,
                              selectedVehicleType: selectedVehicleType,
                              vehicleTypeString: "Car",
                              amountString:tripDirectionDetailsInfo != null?'\$ ${((AssistantMethods.calculateFareAroundFromOriginToDestination(tripDirectionDetailsInfo!) * 2)*107)}'
                                  : "",
                              onTap: (){
                                setState(() {
                                  selectedVehicleType = "Car";
                                });
                              },
                            ),
                            SizedBox(width: 5,),
                            CardVehicleType(
                              darkTheme: darkTheme,
                              assetImageString: "images/CNG_car.png",
                              assetImageScale: 4,
                              selectedVehicleType: selectedVehicleType,
                              vehicleTypeString: "CNG",
                              amountString:tripDirectionDetailsInfo != null?'\$ ${((AssistantMethods.calculateFareAroundFromOriginToDestination(tripDirectionDetailsInfo!) * 1.5)*107).toStringAsFixed(2)}'
                                  : "",
                              onTap: (){
                                setState(() {
                                  selectedVehicleType = "CNG";
                                });
                              },
                            ),
                            SizedBox(width: 5,),
                            CardVehicleType(
                              darkTheme: darkTheme,
                              assetImageString: "images/car5.png",
                              assetImageScale: 9,
                              selectedVehicleType: selectedVehicleType,
                              vehicleTypeString: "Car",
                              amountString:tripDirectionDetailsInfo != null?'\$ ${((AssistantMethods.calculateFareAroundFromOriginToDestination(tripDirectionDetailsInfo!) * 2)*107)}'
                                  : "",
                              onTap: (){
                                setState(() {
                                  selectedVehicleType = "Car";
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
                              Fluttertoast.showToast(msg: "please select a vehicle from \n suggested rides");
                            }

                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.amber.shade400:Colors.blue,
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Center(
                              child: Text(
                                "Request a ride",
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
                          "searching for a driver",
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
                          "Cancel",
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
            )
            /*
            //ui for search location
            Positioned(
                top: 40,
                right: 20,
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.all(20),
                  child: Text(
                    Provider.of<AppInfo>(context).userPickUpLocation != null?(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 24) +'...': 'No se obtiene direccion',
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                )),

             */
          ],
        ),
      ),
    );
  }
}


