
import 'package:firebase_database/firebase_database.dart';

class TripsHistoryModel {
  String? time;
  String? originAddress;
  String? destinationAddress;
  String? status;
  String? fareAmount;
  String? car_details;
  String? driverName;
  String? ratings;

  TripsHistoryModel({
    this.time,
    this.originAddress,
    this.destinationAddress,
    this.status,
    this.fareAmount,
    this.car_details,
    this.driverName,
    this.ratings,
  });

  TripsHistoryModel.fromSnapshot(DataSnapshot dataSnapshot){
    time = (dataSnapshot.value as Map)["time"];
    originAddress = (dataSnapshot.value as Map)["originAddress"];
    destinationAddress = (dataSnapshot.value as Map)["destinationAddress"];
    status = (dataSnapshot.value as Map)["status"];
    fareAmount = (dataSnapshot.value as Map)["fareAmount"];
    car_details = (dataSnapshot.value as Map)["car_details"];
    driverName = (dataSnapshot.value as Map)["driverName"];
    ratings = (dataSnapshot.value as Map)["ratings"];
  }

  TripsHistoryModel.fromJson(Map<String, dynamic> json){
    time = json["created_at"] ?? DateTime.now().toIso8601String();
    originAddress = json["origin_address"] ?? "Desconocido";
    destinationAddress = json["destination_address"] ?? "Desconocido";
    status = json["status"] ?? "Desconocido";
    fareAmount = json["fare_amount"]?.toString() ?? "0";
    
    // Parse driver details if joined
    if (json["drivers"] != null) {
      final driver = json["drivers"] as Map;
      driverName = "${driver["names"] ?? ""} ${driver["surnames"] ?? ""}".trim();
      if (driverName!.isEmpty) driverName = "Conductor";
    } else {
      driverName = json["driver_name"] ?? "Conductor";
    }
    
    // ratings and car_details might not be readily available in the simple query
    ratings = json["rating"]?.toString() ?? "N/A";
    car_details = json["vehicle_type"] ?? "";
  }
}