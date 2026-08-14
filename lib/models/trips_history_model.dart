
import 'dart:developer';
import 'package:firebase_database/firebase_database.dart';

class TripsHistoryModel {
  String? id; // ID de Supabase (UUID) del viaje - permite calificar un ride existente
  String? time;
  String? originAddress;
  String? destinationAddress;
  String? status;
  String? fareAmount;
  String? car_details;
  String? driverName;
  String? driverPhoto; // Foto de perfil del conductor
  String? ratings;
  String? waterLiters;
  String? vehicleType; // Para identificar si es water_truck

  TripsHistoryModel({
    this.id,
    this.time,
    this.originAddress,
    this.destinationAddress,
    this.status,
    this.fareAmount,
    this.car_details,
    this.driverName,
    this.driverPhoto,
    this.ratings,
    this.waterLiters,
    this.vehicleType,
  });

  TripsHistoryModel.fromSnapshot(DataSnapshot dataSnapshot){
    id = (dataSnapshot.value as Map)["id"];
    time = (dataSnapshot.value as Map)["time"];
    originAddress = (dataSnapshot.value as Map)["originAddress"];
    destinationAddress = (dataSnapshot.value as Map)["destinationAddress"];
    status = (dataSnapshot.value as Map)["status"];
    fareAmount = (dataSnapshot.value as Map)["fareAmount"];
    car_details = (dataSnapshot.value as Map)["car_details"];
    driverName = (dataSnapshot.value as Map)["driverName"];
    ratings = (dataSnapshot.value as Map)["ratings"];
    waterLiters = (dataSnapshot.value as Map)["waterLiters"];
  }

  TripsHistoryModel.fromJson(Map<String, dynamic> json){
    id = json["id"] as String?; // Capturar ID de Supabase (UUID)
    time = json["created_at"] ?? DateTime.now().toIso8601String();
    originAddress = json["origin_address"] ?? "Desconocido";
    destinationAddress = json["destination_address"] ?? "Desconocido";
    status = json["status"] ?? "Desconocido";
    fareAmount = json["fare_amount"]?.toString() ?? "0";
    vehicleType = json["vehicle_type"]?.toString();

    // Parse driver details if joined
    if (json["users"] != null) {
      final driver = json["users"] as Map;
      driverName = "${driver["names"] ?? ""} ${driver["surnames"] ?? ""}".trim();
      if (driverName!.isEmpty) driverName = "Conductor";
      if (driver["documents"] != null) {
        final docs = driver["documents"] as Map;
        driverPhoto = docs["imageSelfie"];
      }
    } else {
      driverName = json["driver_name"] ?? "Conductor";
    }

    // ratings: null si no tiene calificación, de lo contrario el valor
    ratings = json["rating"]?.toString();
    car_details = json["vehicle_type"] ?? "";
    waterLiters = json["water_liters"]?.toString() ?? "";
  }
}