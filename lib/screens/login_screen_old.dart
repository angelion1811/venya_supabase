import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ven_app/Assistants/assistant_methods.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/screens/forgot_password_screen.dart';
import 'package:ven_app/screens/main_screen.dart';
import 'package:ven_app/screens/register_screen.dart';
import 'package:ven_app/splashScreen/splash_screen.dart';


class LoginScreenOld extends StatefulWidget {
  const LoginScreenOld({Key? key}) : super(key: key);

  @override
  State<LoginScreenOld> createState() => _LoginScreenOldState();
}

class _LoginScreenOldState extends State<LoginScreenOld> {
  final emailTextEditingContentController = TextEditingController();
  final passwordTextEditingContentController = TextEditingController();
  bool _passwordVisible = false;
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    //validate field of form;
    if(_formKey.currentState!.validate()){
      await firebaseAuth.signInWithEmailAndPassword(
          email: emailTextEditingContentController.text.trim(),
          password: passwordTextEditingContentController.text.trim()
      ).then((auth)  async {
       DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");
        userRef.child(firebaseAuth.currentUser!.uid).once().then((value) async {
          final snap = value.snapshot;
          if(snap.value != null){
            currentUser = auth.user;
            await Fluttertoast.showToast(msg: "Inicio de sesión exitosamente");
            await AssistantMethods.readCurrentOnLineUserInfo();
            Navigator.push(context, MaterialPageRoute(builder: (c)=>MainScreen()));
          } else {
            await Fluttertoast.showToast(msg: "No hay registro con este correo");
            firebaseAuth.signOut();
            Navigator.push(context, MaterialPageRoute(builder: (c)=>SplashScreen()));
          }
        });
      }).catchError((errorMessage){
        Fluttertoast.showToast(msg: "Error ocurrido \n $errorMessage");
      });
    } else {
      Fluttertoast.showToast(msg: "No todos los campos esta llenos");
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
              Image.asset(darkTheme? 'images/VenLogo_dark.jpg':'images/VenLogo.jpg' ),
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
                                    backgroundColor: darkTheme? Colors.amber.shade400:Colors.blue,
                                    foregroundColor: darkTheme? Colors.black:Colors.white,
                                    elevation: 50,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    minimumSize: Size(double.infinity, 50)
                                ),
                                onPressed: (){
                                  _submit();
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
