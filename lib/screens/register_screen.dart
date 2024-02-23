import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/main_screen.dart';
import 'package:ven_app/screens/register_documents_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final nameTextEditingContentController = TextEditingController();
  final emailTextEditingContentController = TextEditingController();
  final phoneTextEditingContentController = TextEditingController();
  final addressTextEditingContentController = TextEditingController();
  final passwordTextEditingContentController = TextEditingController();
  final confirmPasswordTextEditingContentController = TextEditingController();

  bool _passwordVisible = false;
  XFile? imageFile;
  String urlOfUploadedImage = "";

  //declare global key
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    //validate field of form;
    if(_formKey.currentState!.validate()){
      await firebaseAuth.createUserWithEmailAndPassword(
          email: emailTextEditingContentController.text.trim(),
          password: passwordTextEditingContentController.text.trim()
      ).then((auth)  async {
          currentUser = auth.user;
          if(currentUser != null){
            Map userMap = {
              'id': currentUser!.uid,
              'name': nameTextEditingContentController.text.trim(),
              'email': emailTextEditingContentController.text.trim(),
              'address': addressTextEditingContentController.text.trim(),
              'phone': phoneTextEditingContentController.text.trim(),
              "blocked": false,
              "verified": false,
            };
            DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users');
            userRef.child(currentUser!.uid).set(userMap);
          }
          await Fluttertoast.showToast(msg: "usuario registrado con exito");
          Navigator.push(context, MaterialPageRoute(builder: (c)=>RegisterDocumentsScreen()));
      }).catchError((errorMessage){
        Fluttertoast.showToast(msg: "Error ocurrido \n $errorMessage");
      });
    } else {
      Fluttertoast.showToast(msg: "No todos los campos esta llenos");
    }

  }


  chooseImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
// Pick an image.
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    //final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(pickedFile != null){
      setState(() {
        imageFile = pickedFile;
      });
    }
  }


  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(onTap: (){
      FocusScope.of(context).unfocus();
    },
      child: Scaffold(
        body: ListView(
        padding: EdgeInsets.all(0),
        children: [
          Image.asset(darkTheme? 'images/VenLogo_dark.jpg':'images/VenLogo.jpg' ),
          SizedBox(height: 10,),

          Center(child:Text("Registro",
            style: TextStyle(
              color: darkTheme? Colors.amber.shade400: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ) ,),),
          SizedBox( height: 10,),


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
                                        LengthLimitingTextInputFormatter(50)
                                      ],
                                      decoration: InputDecoration(
                                        hintText: "Name",
                                        hintStyle: const TextStyle(
                                          color: Colors.grey
                                        ),
                                        filled: true,
                                        fillColor: darkTheme? Colors.black45: Colors.grey.shade200,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: const BorderSide(
                                            width: 0,
                                            style: BorderStyle.none
                                          )
                                        ),
                                        prefixIcon: Icon(Icons.person, color: darkTheme? Colors.amber.shade400: Colors.grey,)
                                      ),
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      validator: (text){
                                        if(text==null||text.isEmpty){
                                          return "Name can't be empty";
                                        }
                                        if(text.length < 2){
                                          return "Please enter a valid name";
                                        }
                                        if(text.length > 50){
                                          return "Name can't be more than 50";
                                        }
                                      },
                                      onChanged: (text)=>setState(() {
                                        nameTextEditingContentController.text = text;
                                      })
                                  ),
                                  const SizedBox(height: 10,),
                                  TextFormField(
                                    inputFormatters:[
                                      LengthLimitingTextInputFormatter(100)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Email",
                                        hintStyle: const TextStyle(
                                            color: Colors.grey
                                        ),
                                        filled: true,
                                        fillColor: darkTheme? Colors.black45: Colors.grey.shade200,
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(40),
                                            borderSide: const BorderSide(
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
                                  const SizedBox(height: 10,),
                                  IntlPhoneField(
                                    showCountryFlag: false,
                                    dropdownIcon: Icon(Icons.arrow_drop_down, color: darkTheme? Colors.amber.shade400: Colors.grey,),
                                    decoration: InputDecoration(
                                        hintText: "Phone Number",
                                        hintStyle: const TextStyle(
                                            color: Colors.grey
                                        ),
                                        filled: true,
                                        fillColor: darkTheme? Colors.black45: Colors.grey.shade200,
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(40),
                                            borderSide: const BorderSide(
                                                width: 0,
                                                style: BorderStyle.none
                                            )
                                        ),
                                        //prefixIcon: Icon(Icons.person, color: darkTheme? Colors.amber.shade400: Colors.grey,)
                                    ),
                                    initialCountryCode: 'VE',
                                    onChanged: (text) => setState(() {
                                      phoneTextEditingContentController.text = text.completeNumber;
                                    }),
                                  ),
                                  const SizedBox(height: 10,),
                                  TextFormField(
                                      inputFormatters:[
                                        LengthLimitingTextInputFormatter(100)
                                      ],
                                      decoration: InputDecoration(
                                          hintText: "Address",
                                          hintStyle: const TextStyle(
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
                                          return "Address can't be empty";
                                        }
                                        if(text.length < 5){
                                          return "Please enter a valid address";
                                        }
                                        if(EmailValidator.validate(text)==true) {
                                          return null;
                                        }
                                        if(text.length > 100){
                                          return "Address can't be more than 50";
                                        }
                                      },
                                      onChanged: (text)=>setState(() {
                                        addressTextEditingContentController.text = text;
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
                                  TextFormField(
                                      obscureText: !_passwordVisible,
                                      inputFormatters:[
                                        LengthLimitingTextInputFormatter(100)
                                      ],
                                      decoration: InputDecoration(
                                          hintText: "Confirm Password",
                                          hintStyle: const TextStyle(
                                              color: Colors.grey
                                          ),
                                          filled: true,
                                          fillColor: darkTheme? Colors.black45: Colors.grey.shade200,
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(40),
                                              borderSide: const BorderSide(
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
                                          return "Confirm Password can't be empty";
                                        }
                                        if(text.length < 6){
                                          return "Please enter a valid password";
                                        }

                                        if(text.length > 50){
                                          return "Confirm Password can't be more than 50";
                                        }
                                        return null;
                                      },
                                      onChanged: (text)=>setState(() {
                                        confirmPasswordTextEditingContentController.text = text;
                                      })


                                  ),
                                  SizedBox(height: 20,),
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
                                      child: Text('Registrarse',
                                        style: TextStyle(fontSize: 20),
                                      ),

                                                                        ),
                                  SizedBox(height: 20,),
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (c)=>RegisterScreen()));
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
                                      const Text(
                                        "Tienes cuenta",
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 15
                                        ),
                                      ),
                                       const SizedBox(width: 5,),
                                      GestureDetector(
                                        onTap: (){
                                          Navigator.push(context, MaterialPageRoute(builder: (c)=>LoginScreen()));
                                        },
                                        child: Text('Inicia Sesion', style: TextStyle(
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
      ));
  }
}
