
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String? id;
  String? name;
  String? phone;
  String? email;
  String? address;
  dynamic? documents;
  bool? blocked;
  bool? verified;

  UserModel({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.documents,
    this.blocked,
    this.verified,
  });

  UserModel.fromSnapshot(DataSnapshot snapshot){
    id = snapshot.key;
    name = (snapshot.value as dynamic)["name"];
    phone = (snapshot.value as dynamic)["phone"];
    email = (snapshot.value as dynamic)["email"];
    address = (snapshot.value as dynamic)["address"];
    documents = (snapshot.value as dynamic)["documents"];
    blocked = (snapshot.value as dynamic)["blocked"];
    verified = (snapshot.value as dynamic)["verified"];
  }

  UserModel.fromJson(Map jsonData){
    id = jsonData["_id"];
    name = jsonData["name"];
    phone = jsonData["phone"];
    email = jsonData["email"];
    address = jsonData["address"];
    documents = jsonData["documents"];
    blocked = jsonData["blocked"];
    verified = jsonData["verified"];
  }
}