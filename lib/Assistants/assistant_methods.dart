
import 'dart:convert';
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
import 'package:http/http.dart' as http;
import '../models/direction_details_info.dart';

class AssistantMethods {

  static Future<void> readCurrentOnLineUserInfo() async {
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

  static double calculateFareAroundFromOriginToDestination(DirectionDetailsInfo directionDetailsInfo){
    double timeTravelledFareAmountPerMinute = (directionDetailsInfo.distance_value! /60) * 0.1;
    double distanceTraveledFareAmountPerKilometer = (directionDetailsInfo.distance_value!/ 1000) * 0.1;

    //usd
    double totalFareAmount = timeTravelledFareAmountPerMinute*distanceTraveledFareAmountPerKilometer;

    return double.parse(totalFareAmount.toStringAsFixed(1));
  }

  static sendNotificationToDriverNow(String deviceRegistrationToken, String userRideRequestId, context) async {
    String destinationAddress = userDropOffAddress;

    Map<String, String> headerNotification = {
      "Content-Type": "application/json",
      "Authorization": cloudMessagingServerToken,
    };

    Map bodyNotification = {
      "body": "Destino: \n $destinationAddress",
      "title": "Solicitud de viaje"
    };

    Map dataMap = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "rideRequestId": userRideRequestId
    };

    Map officialNotificationFormat = {
      "notification":bodyNotification,
      "data": dataMap,
      "prority": "high",
      "to": deviceRegistrationToken,
    };

    print(officialNotificationFormat.toString());

    var responseNotification = await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
       //Uri.parse('https://api.rnfirebase.io/messaging/send'),
      headers: headerNotification,
      body: jsonEncode(officialNotificationFormat)
    );
    
  }
}