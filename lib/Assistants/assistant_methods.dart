
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/Assistants/request_assistant.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/global/map_key.dart';
import 'package:ven_app/infoHandler/app_info.dart';
import 'package:ven_app/models/directions.dart';
import 'package:ven_app/models/user_model.dart';

import '../models/direction_details_info.dart';

class AssistantMethods {

  static void readCurrentOnLineUserInfo() async {
    currentUser = firebaseAuth.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance
      .ref()
      .child("users")
      .child(currentUser!.uid);

    userRef.once().then((snap){
      if(snap.snapshot.value != null){
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
      }
    });
  }

  static Future<String> searchAddressForGeographicCoordinates( double clatitude, double clongitude , context) async {

    //String apiUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey';
    String apiUrl = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${clatitude}&lon=${clongitude}';
    print("apiUrl");
    print(apiUrl);
    String humanReadableAddress = "";
    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);
    print(requestResponse);
    //log("requestResponse $requestResponse");
    if(requestResponse != "Error Ocurred. Failed. No Response."){
      humanReadableAddress = requestResponse['display_name'];
      Directions userPickAddress = Directions();
      userPickAddress.locationLatitude = clatitude;
      userPickAddress.locationLongitude = clongitude;
      userPickAddress.locationName = humanReadableAddress;
      Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickAddress);
    }
    return humanReadableAddress;
  }

  static Future<DirectionDetailsInfo> obtainOriginToDestinationDirectionDetails(LatLng originPosition, LatLng destinationPosition) async {
    /*
    //google maps
    String urlOriginToDestinationDirectionsDetails = 'https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition
        .latitude},${originPosition.longitude}&destination=${destinationPosition
        .latitude},${destinationPosition.longitude}&key=$mapKey';
    */
    String urlOriginToDestinationDirectionsDetails = 'http://router.project-osrm.org/route/v1/driving/${originPosition.longitude},${originPosition.latitude};${destinationPosition.longitude},${destinationPosition.latitude}?steps=true&annotations=true&geometries=geojson&overview=full';
    print('urlOriginToDestinationDirectionsDetails');
    print(urlOriginToDestinationDirectionsDetails);

    var responseDirectionApi = await RequestAssistant.receiveRequest(
        urlOriginToDestinationDirectionsDetails);

    print("responseDirectionApi");
    print(responseDirectionApi);
    /*
    if (responseDirectionApi == "Error Ocurred. Failed. No Response.") {
      return null;
    }
     */



    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
    directionDetailsInfo.e_points =
    responseDirectionApi["routes"][0]["geometry"]["coordinates"];

    directionDetailsInfo.distance_text = (responseDirectionApi["routes"][0]["distance"]).toString();
    directionDetailsInfo.distance_value = (responseDirectionApi["routes"][0]["distance"]).toInt();
    directionDetailsInfo.duration_text = (responseDirectionApi["routes"][0]["duration"]).toString();
    directionDetailsInfo.duration_value = (responseDirectionApi["routes"][0]["duration"]).toInt();

    return directionDetailsInfo;
  }
}