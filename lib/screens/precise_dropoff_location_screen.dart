import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';
import 'package:ven_app/screens/search_places_screen.dart';

import '../Assistants/assistant_methods.dart';
import '../Assistants/request_assistant.dart';
import '../Helpers/custom_functions.dart';
import '../infoHandler/app_info.dart';
import '../models/directions.dart';
import '../models/predicted_places.dart';
import '../widgets/place_prediction_tile.dart';

class PreciseDropOffLocationScreen extends StatefulWidget {
  const PreciseDropOffLocationScreen({Key? key}) : super(key: key);

  @override
  State<PreciseDropOffLocationScreen> createState() => _PreciseDropOffLocationScreenState();
}

class _PreciseDropOffLocationScreenState extends State<PreciseDropOffLocationScreen> {

  LatLng? dropOffLocation;
  loc.Location location = loc.Location();
  String? _address;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  Position? userCurrentPosition;
  double bottonPaddingOfMap = 0;

  List<PredictedPlaces> placesPredictedList = [];


  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> _scafforState = GlobalKey<ScaffoldState>();

  locateUserPosition(context) async {
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng latLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 15);

    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humaneReableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(userCurrentPosition!.latitude, userCurrentPosition!.longitude, context);
    return;
  }

  locateDropOffPosition() async {
    var destinationPosition = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    LatLng latLngPosition = LatLng(destinationPosition!.locationLatitude!, destinationPosition!.locationLongitude!);

    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 15);

    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    return;
  }

  getAddressFromLatlng() async {
    try {
      String humaneReableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(dropOffLocation!.latitude, dropOffLocation!.longitude, context);

      setState(() {
        Directions userDropOffAddress = Directions();
        userDropOffAddress.locationLatitude = dropOffLocation!.latitude;
        userDropOffAddress.locationLongitude = dropOffLocation!.longitude;
        userDropOffAddress.locationName = humaneReableAddress;

        Provider.of<AppInfo>(context, listen: false).updateDroffLocationAddress(userDropOffAddress);
      });
    } catch(e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body:  Stack(
            children: [
              GoogleMap(
                padding: EdgeInsets.only(top: 100, bottom: bottonPaddingOfMap),
                mapType: MapType.normal,
                myLocationEnabled: true,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: true,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller){
                  _controllerGoogleMap.complete(controller);
                  newGoogleMapController = controller;
                  setState(() {
                    bottonPaddingOfMap = 50;
                  });
                  print("changing location");
                  locateUserPosition(context);
                },
                onCameraMove:(CameraPosition? position){
                  if(dropOffLocation != position!.target){
                    try {
                      setState(() {
                        dropOffLocation = position.target;
                      });
                    } catch(e){

                    }
                  }
                },
                onCameraIdle: () {
                  getAddressFromLatlng();
                },
              ),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: Image.asset('images/pick_old_3.png', height: 25, width: 25,),
                ),
              ),
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(5, 50, 5, 5),
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
                              Padding(
                                padding: EdgeInsets.all(5),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      ElevatedButton(
                                          onPressed: () async {
                                            var responseFromSearch = await Navigator.push(context, MaterialPageRoute(builder: (c)=> SearchPlacesScreen(place: 'destiny',)));
                                            if(responseFromSearch == 'obtainedDropoff'){
                                              await locateDropOffPosition();
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: darkTheme? Colors.amber.shade400: Colors.blue,
                                              textStyle: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              )
                                          ),
                                          child: Row(
                                              children:[
                                                Icon(Icons.search, color: darkTheme ? Colors.black: Colors.white ),
                                                SizedBox(width: 10,),
                                                Text("Buscar",
                                                  style: TextStyle(
                                                    color: darkTheme ? Colors.black: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ])
                                      ),]
                                ),
                              ),
                              SizedBox(height: 10,),
                              Container(
                                decoration: BoxDecoration(
                                    color: darkTheme? Colors.grey.shade900 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10)
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: 5,),
                                    Padding(
                                      padding: EdgeInsets.all(5),
                                      child: GestureDetector(
                                        onTap: () async {

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

                            ],
                          )
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: () async {
                      await getAddressFromLatlng();
                      await locateUserPosition(context);
                      Navigator.pop(context, "obtainedDropoff");
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: darkTheme? Colors.amber.shade400: Colors.blue,
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )
                    ),
                    child: Text("Asignar localización de destino",
                      style: TextStyle(
                        color: darkTheme ? Colors.black: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              )
            ]
        ),
      ),
    );
  }
}
