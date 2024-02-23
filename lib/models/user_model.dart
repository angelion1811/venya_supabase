
import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String? id;
  String? name;
  String? phone;
  String? email;
  String? address;
  dynamic? documents;
  bool? blocked;

  UserModel({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.documents,
  });

  UserModel.fromSnapshot(DataSnapshot snapshot){
    id = snapshot.key;
    name = (snapshot.value as dynamic)["name"];
    phone = (snapshot.value as dynamic)["phone"];
    email = (snapshot.value as dynamic)["email"];
    address = (snapshot.value as dynamic)["address"];
    documents = (snapshot.value as dynamic)["documents"];
    blocked = (snapshot.value as dynamic)["blocked"];
  }
}