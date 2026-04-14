import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/Assistants/assistant_methods.dart';
import 'package:ven_app/Services/supabase_service.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/models/user_model.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/main_screen.dart';
import 'package:ven_app/screens/register_documents_screen.dart';

import '../infoHandler/app_info.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  startTimer(){
    Timer(Duration(seconds: 3), ()async{
      // Verificar si hay sesión activa en Supabase
      if (!SupabaseService.isAuthenticated) {
        Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
        return;
      }

      // Actualizar token en AppInfo
      Provider.of<AppInfo>(context, listen: false).updateToken(SupabaseService.accessToken ?? '');

      dynamic res = await SupabaseService.getProfile();

      if(res['statusCode'] != 200){
        await SupabaseService.logout();
        Provider.of<AppInfo>(context, listen: false).updateToken("");
        Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
        return;
      }
      try {
        log('Perfil obtenido: ${res['data']}');
        userModelCurrentInfo = SupabaseService.userRecordToModel(res['data']);

        log('$userModelCurrentInfo');

        if (userModelCurrentInfo!.documents == null) {
          Navigator.push(context,
              MaterialPageRoute(builder: (c) => RegisterDocumentsScreen()));
          return;
        }
        if (userModelCurrentInfo!.blocked == true) {
          Fluttertoast.showToast(msg: "Usuario Bloquedo");
          await SupabaseService.logout();
          Provider.of<AppInfo>(context, listen: false).updateToken("");
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => LoginScreen()));
          return;
        }
        if (userModelCurrentInfo!.verified == false) {
          await SupabaseService.logout();
          Provider.of<AppInfo>(context, listen: false).updateToken("");
          Fluttertoast.showToast(msg: "Usuario no verificado");
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => LoginScreen()));
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
      } catch(e){
        log('error $e');
        await SupabaseService.logout();
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
