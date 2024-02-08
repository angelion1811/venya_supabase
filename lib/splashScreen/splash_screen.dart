import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:ven_app/Assistants/assistant_methods.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  startTimer(){
    Timer(Duration(seconds: 3), ()async{
      if(await firebaseAuth.currentUser != null){
        await AssistantMethods.readCurrentOnLineUserInfo();
        Navigator.push(context, MaterialPageRoute(builder: (c)=>MainScreen()));
      }else{
        Navigator.push(context, MaterialPageRoute(builder: (c)=>LoginScreen()));
      }
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
