import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/Assistants/assistant_methods.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/models/user_model.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/main_screen.dart';
import 'package:ven_app/screens/register_documents_screen.dart';

import '../Assistants/request_assistant.dart';
import '../infoHandler/app_info.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  startTimer(){
    Timer(Duration(seconds: 3), ()async{
      var token = Provider
          .of<AppInfo>(context, listen: false)
          .token;

      log('token: ${token}');

      if (token.isEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
        return;
      }

      dynamic res = await RequestAssistant.getProfile('$token');

      if(res.statusCode != 200){
        Provider.of<AppInfo>(context, listen: false).updateToken("");
        Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
        return;
      }
      try {
        var body = jsonDecode(res.body) as Map;
        log(res.body);
        userModelCurrentInfo = UserModel.fromJson(body['data']);

        log('$userModelCurrentInfo');

        if (userModelCurrentInfo!.documents == null) {
          Navigator.push(context,
              MaterialPageRoute(builder: (c) => RegisterDocumentsScreen()));
          return;
        }
        if (userModelCurrentInfo!.blocked == true) {
          Fluttertoast.showToast(msg: "Usuario Bloquedo");
          Provider.of<AppInfo>(context, listen: false).updateToken("");
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => LoginScreen()));
          return;
        }
        if (userModelCurrentInfo!.verified == false) {
          Provider.of<AppInfo>(context, listen: false).updateToken("");
          Fluttertoast.showToast(msg: "Usuario no verificado");
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => LoginScreen()));
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
      } catch(e){
        log('error $e');
         Provider.of<AppInfo>(context, listen: false).updateToken("");
          Fluttertoast.showToast(msg: "Error");
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => LoginScreen()));
          return;

      }
    });

  }
  @override
  void initState() {
    //Todo Implementa inistate
    super.initState();
    startTimer();

  }
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: darkTheme? Colors.black: Colors.white,
      body: Center(
        child:Image.asset(darkTheme? 'images/logo_dark.png':'images/logo.png' ),
      ),
    );
  }
}
