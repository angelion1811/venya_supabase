
import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String? phone;
  String? name;
  String? id;
  String? email;
  String? address;

  UserModel({
    this.name,
    this.phone,
    this.email,
    this.id,
    this.address,
  });

  UserModel.fromSnapshot(DataSnapshot snapshot){
    id = snapshot.key;
    phone = (snapshot.value as dynamic)["phone"];
    name = (snapshot.value as dynamic)["name"];
    email = (snapshot.value as dynamic)["email"];
    address = (snapshot.value as dynamic)["address"];


  }
}