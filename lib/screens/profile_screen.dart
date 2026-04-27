import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/screens/change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final nameTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  final addressTextEditingController = TextEditingController();

  DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");

  Future<void> showUserNameDialogAlert(BuildContext context, String name){
    nameTextEditingController.text = name;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Actualizacion"),
            content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameTextEditingController,
                    )
                  ],
                )
            ),
            actions: [
              TextButton(onPressed: (){}, child: Text("Cancelar", style: TextStyle(color: Colors.red),)),
              TextButton(
                  onPressed: (){
                    userRef.child(firebaseAuth.currentUser!.uid).update({
                      "name": nameTextEditingController.text.trim()
                    }).then((value){
                      nameTextEditingController.clear();
                      Fluttertoast.showToast(msg: "Actualizado Exitoso \n Reiniciar la App para ver cambios");
                    }).catchError((errorMessage){
                      Fluttertoast.showToast(msg: "Error Ocurred \n $errorMessage");

                    });
                    Navigator.pop(context);
                  },
                  child: Text("Aceptar", style: TextStyle(color: Colors.black),)
              ),
            ],
          );
        }
    );
  }
  Future<void> showUserPhoneDialogAlert(BuildContext context, String phone){
    phoneTextEditingController.text = phone;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Actualizacion"),
            content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: phoneTextEditingController,
                    )
                  ],
                )
            ),
            actions: [
              TextButton(onPressed: (){}, child: Text("Cancelar", style: TextStyle(color: Colors.red),)),
              TextButton(
                  onPressed: (){
                    userRef.child(firebaseAuth.currentUser!.uid).update({
                      "phone": phoneTextEditingController.text.trim()
                    }).then((value){
                      phoneTextEditingController.clear();
                      Fluttertoast.showToast(msg: "Actualizado Exitoso \n Reiniciar la App para ver cambios");
                    }).catchError((errorMessage){
                      Fluttertoast.showToast(msg: "Error Ocurred \n $errorMessage");

                    });
                    Navigator.pop(context);
                  },
                  child: Text("Aceptar", style: TextStyle(color: Colors.black),)
              ),
            ],
          );
        }
    );
  }
  Future<void> showUserAddressDialogAlert(BuildContext context, String address){
    addressTextEditingController.text = address;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Actualizacion"),
            content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: addressTextEditingController,
                    )
                  ],
                )
            ),
            actions: [
              TextButton(onPressed: (){}, child: Text("Cancelar", style: TextStyle(color: Colors.red),)),
              TextButton(
                  onPressed: (){
                    userRef.child(firebaseAuth.currentUser!.uid).update({
                      "address": addressTextEditingController.text.trim()
                    }).then((value){
                      addressTextEditingController.clear();
                      Fluttertoast.showToast(msg: "Actualizado Exitoso \n Reiniciar la App para ver cambios");
                    }).catchError((errorMessage){
                      Fluttertoast.showToast(msg: "Error Ocurred \n $errorMessage");
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Aceptar", style: TextStyle(color: Colors.black),)
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: (){
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
          title: Text(
            "Pantalla de perfil",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 50),
            child: Column(
              children: [
                Container(
                    padding: EdgeInsets.all(50),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, color: Colors.white,),
                ),

                SizedBox(height: 30,),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${userModelCurrentInfo!.names!}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    IconButton(
                      onPressed: (){
                        showUserNameDialogAlert(context, userModelCurrentInfo!.names!);
                      },
                      icon: Icon(Icons.edit)
                    )
                  ],
                ),

                Divider(
                  thickness: 1,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${userModelCurrentInfo!.phone!}",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    IconButton(
                        onPressed: (){
                          showUserPhoneDialogAlert(context, userModelCurrentInfo!.phone!);
                        },
                        icon: Icon(Icons.edit)
                    )
                  ],
                ),

                Divider(
                  thickness: 1,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${userModelCurrentInfo!.address!}",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    IconButton(
                        onPressed: (){
                          showUserAddressDialogAlert(context, userModelCurrentInfo!.address!);
                        },
                        icon: Icon(Icons.edit)
                    )
                  ],
                ),

                Divider(
                  thickness: 1,
                ),
                Text(
                  "${userModelCurrentInfo!.email!}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => const ChangePasswordScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Cambiar contraseña", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
