import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ven_app/Assistants/assistant_methods.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/main_screen.dart';
import 'package:ven_app/screens/register_documents_screen.dart';

class SplashScreenOld extends StatefulWidget {
  const SplashScreenOld({Key? key}) : super(key: key);

  @override
  State<SplashScreenOld> createState() => _SplashScreenOldState();
}

class _SplashScreenOldState extends State<SplashScreenOld> {

  startTimer(){
    Timer(Duration(seconds: 3), ()async{
      if(await firebaseAuth.currentUser == null) {
        Navigator.push(context, MaterialPageRoute(builder: (c)=>LoginScreen()));
        return;
      }
      await AssistantMethods.readCurrentOnLineUserInfo();
      print("data of user");
      print(userModelCurrentInfo);
      await Timer(Duration(seconds: 3),()async{
        print("userModelCurrentInfo");
        if(userModelCurrentInfo == null){
          firebaseAuth.signOut();
          Navigator.push(context, MaterialPageRoute(builder: (c)=>LoginScreen()));
          return;
        }
        if(userModelCurrentInfo!.documents == null){
          Navigator.push(context, MaterialPageRoute(builder: (c)=>RegisterDocumentsScreen()));
          return;
        }
        if(userModelCurrentInfo!.blocked == true){
          Fluttertoast.showToast(msg: "Usuario Bloquedo");
          firebaseAuth.signOut();
          Navigator.push(context, MaterialPageRoute(builder: (c)=>LoginScreen()));
          return;
        }

        if(userModelCurrentInfo!.verified == false){
          Fluttertoast.showToast(msg: "Usuario no verificado");
          firebaseAuth.signOut();
          Navigator.push(context, MaterialPageRoute(builder: (c)=>LoginScreen()));
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (c)=>MainScreen()));

      });
    });
  }

  @override
  void initState(){
    //Todo Implementa inistate
    super.initState();

    startTimer();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Ven Ya',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}
