
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/Assistants/request_assistant.dart';
import 'package:ven_app/Services/supabase_service.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/global/map_key.dart';
import 'package:ven_app/infoHandler/app_info.dart';
import 'package:ven_app/models/directions.dart';
import 'package:ven_app/models/trips_history_model.dart';
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
        print("hay datos de usuario");
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
        print(userModelCurrentInfo);
      }
    });
    return;
  }

  static Future<String> searchAddressForGeographicCoordinates( double clatitude, double clongitude , context) async {

    // Nominatim reverse geocoding - requiere User-Agent con email del usuario
    final userEmail = SupabaseService.currentUser?.email ?? 'anonimo@venapp.com';
    String apiUrl = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${clatitude}&lon=${clongitude}';
    String humanReadableAddress = "";

    try {
      var requestResponse = await RequestAssistant.receiveRequest(
        apiUrl,
        headers: {
          'User-Agent': 'VenApp/1.0 ($userEmail)',
        },
      );

      if(requestResponse != "Error Ocurred. Failed. No Response."){
        humanReadableAddress = requestResponse['display_name'] ?? '';
        print("Dirección obtenida de Nominatim: $humanReadableAddress");

        Directions userPickAddress = Directions();
        userPickAddress.locationLatitude = clatitude;
        userPickAddress.locationLongitude = clongitude;
        userPickAddress.locationName = humanReadableAddress;
        Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickAddress);
      } else {
        print("Error: Nominatim no respondió");
      }
    } catch (e) {
      print("Error en reverse geocoding: $e");
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

    var responseDirectionApi = await RequestAssistant.receiveRequest(
        urlOriginToDestinationDirectionsDetails);
    /*
    if (responseDirectionApis == "Error Ocurred. Failed. No Response.") {
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
    double timeTravelledFareAmountPerMinute = (directionDetailsInfo.duration_value! /60) * 0.1;
    double distanceTraveledFareAmountPerKilometer = (directionDetailsInfo.distance_value!/ 1000) * 0.1;
    //usd
    double totalFareAmount = timeTravelledFareAmountPerMinute+distanceTraveledFareAmountPerKilometer;

    return double.parse(totalFareAmount.toStringAsFixed(1));
  }

  static sendNotificationToDriverNow(String deviceRegistrationToken, String userRideRequestId, context) async {
    print("sendNotificationToDriverNow");
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

    var responseNotification = await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
       //Uri.parse('https://api.rnfirebase.io/messaging/send'),
      headers: headerNotification,
      body: jsonEncode(officialNotificationFormat)
    );
    
  }

  static void readTripsKeysForOnlineUser(context){
    FirebaseDatabase.instance.ref().child("All Ride Requests").orderByChild("userName").equalTo(userModelCurrentInfo!.names!).once().then((snap){
      if(snap.snapshot.value != null){
        print("readTripsKeysForOnlineUser");

        Map keysTripsId = snap.snapshot.value as Map;
        print("keysTripsId");
        print(keysTripsId);

        //count total number of trips and share it with provider

        int overAllTripsCounter = keysTripsId.length;

        Provider.of<AppInfo>(context, listen: false).updateOverAllTripsCounter(overAllTripsCounter);

        //share trips keys with Provider

        List<String> tripsKeysList = [];
        
        keysTripsId.forEach((key, value) { 
          tripsKeysList.add(key);
        });
        Provider.of<AppInfo>(context, listen: false).updateOverAllTripsKeys(tripsKeysList);

        //get trips keys data - read trips complete information

        readTripsHistoryInformation(context);
      }
    });
  }

  static void readTripsHistoryInformation(context){
    var tripsAllKeys = Provider.of<AppInfo>(context, listen: false).historyTripsKeysList;

    for(String eachKey in tripsAllKeys){
      FirebaseDatabase.instance.ref()
          .child("All Ride Requests")
          .child(eachKey)
          .once()
          .then((snap){
            var eachTripHistory = TripsHistoryModel.fromSnapshot(snap.snapshot);

            if((snap.snapshot.value as Map)["status"] == "ended"){
              //update or add each history to OverAllTrips History date list
              Provider.of<AppInfo>(context, listen: false).updateOverAllTripsHistoryInformation(eachTripHistory);
            }
      });
    }
  }


  static  Future<bool> checkIfRecordExists(String nodo, String fieldName, String fieldValue) async {
    try {
      print("checkIfRecordExists");
      DatabaseReference ref = await FirebaseDatabase.instance.ref().child(nodo);
      print("checkIfRecordExists 2");
      Query query = ref.orderByChild(fieldName)
          .equalTo(fieldValue)
          .limitToFirst(1);
      print("checkIfRecordExists 3");
      DatabaseEvent event = await query.once();
      print("checkIfRecordExists 4");
      DataSnapshot snapshot = event.snapshot;
      print("checkIfRecordExists 5");
      return snapshot.value != null;
    }catch(e){
      print(e);
      return false;
    }
  }

    
}