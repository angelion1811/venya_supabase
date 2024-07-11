import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/register_screen.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  final emailTextEditingController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void _submit(){
    firebaseAuth.sendPasswordResetEmail(
        email: emailTextEditingController.text.trim()
    ).then((value){
      Fluttertoast.showToast(msg: "Hemos enviado un correo para recuper contrase'a, por favor verificar el correo electronico ");
    }).catchError((error, stackTrace){
      Fluttertoast.showToast(msg: "Error Ocurrido: \n ${error.toString()}");
    });
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
              Center(child:Text("Olvido Contraseña?",
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
                                    emailTextEditingController.text = text;
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
                                child: Text('Enviar Correo',
                                  style: TextStyle(fontSize: 20),
                                ),

                              ),
                              SizedBox(height: 30,),
                              GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (c)=>LoginScreen()));
                                },
                                child: Text('Iniciar sesión',
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
                                    "Tienes cuenta",
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
