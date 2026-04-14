import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/Assistants/assistant_methods.dart';
import 'package:ven_app/Services/supabase_service.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/screens/forgot_password_screen.dart';
import 'package:ven_app/screens/main_screen.dart';
import 'package:ven_app/screens/register_screen.dart';
import 'package:ven_app/splashScreen/splash_screen.dart';

import '../infoHandler/app_info.dart';
import '../models/user_model.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailTextEditingContentController = TextEditingController();
  final passwordTextEditingContentController = TextEditingController();
  bool _passwordVisible = false;
  bool isSubmitted = false;
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    //validate field of form;
    if(_formKey.currentState!.validate()){
      Map<String, dynamic> userLogin = {
        'email': emailTextEditingContentController.text.trim(),
        'password': passwordTextEditingContentController.text.trim()
      };

      var res = await SupabaseService.loginUser(userLogin);
      if(res['statusCode'] == 404){
        Fluttertoast.showToast(msg: "Usuario Invalido");
        setState(()=> isSubmitted = false);
      } else if(res['statusCode'] == 400) {
        var errors = res['errors'] as Map<String, dynamic>;
        for (String key in errors.keys) {
          for (String value in errors[key]) {
            await Fluttertoast.showToast(msg: "$key: ${value}");
          }
        }
        setState(()=> isSubmitted = false);
      } else if(res['statusCode'] == 200){
        Fluttertoast.showToast(msg: "Inicio de sesión de usuario exitosamente");
        Provider.of<AppInfo>(context, listen: false).updateToken(res['token'] ?? '');
        userModelCurrentInfo = SupabaseService.userRecordToModel(res['data']);
        Navigator.push(context, MaterialPageRoute(builder: (c) => SplashScreen()));
      } else {
        Fluttertoast.showToast(msg: "error");
        setState(()=> isSubmitted = false);
      }

    } else {
      Fluttertoast.showToast(msg: "error");

      setState(()=> isSubmitted = false);
    }

  }
  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap:(){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: ListView(
            padding: EdgeInsets.all(0),
            children: [
              Image.asset(darkTheme? 'images/logo_dark.png':'images/logo.png' ),
              SizedBox(height: 20,),
              Center(child:Text("Inicio de sesión",
                style: TextStyle(
                  color: darkTheme? Colors.amber.shade400: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ) ,),),
              Padding(padding: const EdgeInsets.fromLTRB(15, 20, 15, 50),
                  child:Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextFormField(
                                  inputFormatters:[
                                    LengthLimitingTextInputFormatter(100)
                                  ],
                                  decoration: InputDecoration(
                                      hintText: "Email",
                                      hintStyle: TextStyle(
                                          color: Colors.grey
                                      ),
                                      filled: true,
                                      fillColor: darkTheme? Colors.black45: Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: BorderSide(
                                              width: 0,
                                              style: BorderStyle.none
                                          )
                                      ),
                                      prefixIcon: Icon(Icons.person, color: darkTheme? Colors.amber.shade400: Colors.grey,)
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (text){
                                    if(text==null||text.isEmpty){
                                      return "email can't be empty";
                                    }
                                    if(text.length < 2){
                                      return "Please enter a valid name";
                                    }
                                    if(EmailValidator.validate(text)==true) {
                                      return null;
                                    }
                                    if(text.length > 50){
                                      return "Email can't be more than 50";
                                    }
                                  },
                                  onChanged: (text)=>setState(() {
                                    emailTextEditingContentController.text = text;
                                  })


                              ),
                              SizedBox(height: 10,),
                              TextFormField(
                                  obscureText: !_passwordVisible,
                                  inputFormatters:[
                                    LengthLimitingTextInputFormatter(100)
                                  ],
                                  decoration: InputDecoration(
                                      hintText: "Password",
                                      hintStyle: TextStyle(
                                          color: Colors.grey
                                      ),
                                      filled: true,
                                      fillColor: darkTheme? Colors.black45: Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: BorderSide(
                                              width: 0,
                                              style: BorderStyle.none
                                          )
                                      ),
                                      prefixIcon: Icon(Icons.person, color: darkTheme? Colors.amber.shade400: Colors.grey,),
                                      suffixIcon: IconButton(
                                        icon:Icon(
                                          _passwordVisible? Icons.visibility: Icons.visibility_off,
                                          color: darkTheme? Colors.amber.shade400: Colors.grey,
                                        ),
                                        onPressed: (){
                                          setState(() {
                                            _passwordVisible = !_passwordVisible;
                                          });
                                        },
                                      )
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (text){
                                    if(text==null||text.isEmpty){
                                      return "Password can't be empty";
                                    }
                                    if(text.length < 6){
                                      return "Please enter a valid password";
                                    }

                                    if(text.length > 50){
                                      return "Password can't be more than 50";
                                    }
                                    return null;
                                  },
                                  onChanged: (text)=>setState(() {
                                    passwordTextEditingContentController.text = text;
                                  })


                              ),
                              SizedBox(height: 10,),
                             ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: isSubmitted? Colors.blueGrey.shade100: darkTheme? Colors.amber.shade400:Colors.blue,
                                    foregroundColor: darkTheme? Colors.black:Colors.white,
                                    elevation: 50,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    minimumSize: Size(double.infinity, 50)
                                ),
                                onPressed: (){
                                  if(isSubmitted == false){
                                    setState(()=> isSubmitted = true);
                                    _submit();
                                  } else {
                                    Fluttertoast.showToast(msg: "esperando respuesta...");
                                  }
                                },
                                child: Text('Inicio de sesión',
                                  style: TextStyle(fontSize: 20),
                                ),

                              ),
                              SizedBox(height: 30,),
                              GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (c)=>ForgotPasswordScreen()));
                                },
                                child: Text('¿Has olvidado tu contraseña?',
                                  style: TextStyle(
                                      color: darkTheme? Colors.amber.shade400: Colors.blue
                                  ),
                                ),
                              ),
                              SizedBox(height: 20,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Ya tienes cuenta?",
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15
                                    ),
                                  ),
                                  SizedBox(width: 5,),
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (c)=>RegisterScreen()));
                                    },
                                    child: Text('Registrate', style: TextStyle(
                                        fontSize: 15,
                                        color: darkTheme ? Colors.amber.shade400: Colors.blue
                                    ),),
                                  )

                                ],
                              )
                            ],
                          ),
                        ),
                      ])
              ),
            ]),
      ),
    );
  }
}
