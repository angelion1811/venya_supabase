
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/Assistants/assistant_methods.dart';
import 'package:ven_app/Helpers/custom_functions.dart';

import '../global/map_key.dart';
import '../infoHandler/app_info.dart';
import '../models/directions.dart';

class PrecisePickUpLocationScreen extends StatefulWidget {
  const PrecisePickUpLocationScreen({Key? key}) : super(key: key);

  @override
  State<PrecisePickUpLocationScreen> createState() => _PrecisePickUpLocationScreenState();
}

class _PrecisePickUpLocationScreenState extends State<PrecisePickUpLocationScreen> {

  LatLng? pickLocation;
  loc.Location location = loc.Location();
  String? _address;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  Position? userCurrentPosition;
  double bottonPaddingOfMap = 0;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> _scafforState = GlobalKey<ScaffoldState>();

  locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng latLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 15);

    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humaneReableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(userCurrentPosition!.latitude, userCurrentPosition!.longitude, context);
    return;
  }

  getAddressFromLatlng() async {
    try {
      String humaneReableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(pickLocation!.latitude, pickLocation!.longitude, context);

      setState(() {
        Directions userPickUpAddress = Directions();
        userPickUpAddress.locationLatitude = pickLocation!.latitude;
        userPickUpAddress.locationLongitude = pickLocation!.longitude;
        userPickUpAddress.locationName = humaneReableAddress;

        Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);
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
                locateUserPosition();
              },
              onCameraMove:(CameraPosition? position){
                if(pickLocation != position!.target){
                  try{
                    setState(() {
                      pickLocation = position.target;
                    });
                  } catch(e) {

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
                padding: const EdgeInsets.only(bottom: 35.0),
                child: Image.asset('images/pick_old_3.png', height: 45, width: 45,),
              ),
            ),

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
                    displayLocationString(Provider.of<AppInfo>(context).userPickUpLocation),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                )
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
                          await locateUserPosition();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          primary: darkTheme? Colors.amber.shade400: Colors.blue,
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )
                        ),
                        child: Text("Asignar localización de origen"),
                      ),
                    ),

                )
          ]
        ),
      ),
    );
  }
}
