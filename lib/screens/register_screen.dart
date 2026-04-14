import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/Services/supabase_service.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/models/user_model.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/main_screen.dart';
import 'package:ven_app/screens/register_documents_screen.dart';

import '../Assistants/assistant_methods.dart';
import '../Helpers/custom_functions.dart';
import '../infoHandler/app_info.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final namesTextEditingContentController = TextEditingController();
  final surnamesTextEditingContentController = TextEditingController();
  final identificationNumberTextEditingContentController = TextEditingController();
  final emailTextEditingContentController = TextEditingController();
  final phoneTextEditingContentController = TextEditingController();
  final addressTextEditingContentController = TextEditingController();
  final passwordTextEditingContentController = TextEditingController();
  final confirmPasswordTextEditingContentController = TextEditingController();
  bool isSubmitted = false;

  List<Map> indetificationTypes = [
    {
      "text":"V-Cedula Venezolana",
      "value":"V"
    },
    {
      "text":"E-Cedula Extranjera",
      "value":"E"
    },
    {
      "text":"P-Pasaporte",
      "value":"P"
    }
  ];
  String? selectedIndentificationType;

  bool _passwordVisible = false;


  //declare global key
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    //validate field of form;
    if (_formKey.currentState!.validate()) {
        Map<String, dynamic> userMap = {
          'names': namesTextEditingContentController.text.trim(),
          'surnames': surnamesTextEditingContentController.text.trim(),
          'email': emailTextEditingContentController.text.trim(),
          'password': passwordTextEditingContentController.text.trim(),
          'identification_type': selectedIndentificationType,
          'identification_number': identificationNumberTextEditingContentController
              .text.trim(),
          'address': addressTextEditingContentController.text.trim(),
          'phone': phoneTextEditingContentController.text.trim()
        };

        dynamic res = await SupabaseService.registerUser(userMap);
        print("result get");
        print(res['statusCode']);
        print(res);

        if(res['statusCode'] == 400) {
          var errors = res['errors'] as Map<String, dynamic>;
          for (String key in errors.keys) {
            for (String value in errors[key]) {
              await Fluttertoast.showToast(msg: "$key: ${value}");
            }
          }
          setState(()=> isSubmitted = false);
        }

        if(res['statusCode'] == 200){
          Provider.of<AppInfo>(context, listen: false).updateToken(res['token'] ?? '');

          userModelCurrentInfo = SupabaseService.userRecordToModel(res['data']);

          print('userModelCurrentInfo');
          print(userModelCurrentInfo!.id);
          await Fluttertoast.showToast(msg: "usuario registrado con exito");
          Navigator.push(context, MaterialPageRoute(builder: (c) => RegisterDocumentsScreen()));
        }

    } else {
      Fluttertoast.showToast(msg: "No todos los campos esta llenos");
      setState(() => isSubmitted = false);
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
                Image.asset(darkTheme? 'images/logo_dark.png':'images/logo.png' ),
                SizedBox(height: 20,),
                Center(child:Text("Registro",
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
                                      LengthLimitingTextInputFormatter(50)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Nombres",
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
                                      if(defaultValidator(text)!= null){
                                        return defaultValidator(text, maxLength: 100);
                                      }
                                    },
                                    onChanged: (text)=>setState(() {
                                      namesTextEditingContentController.text = text;
                                    })
                                ),
                                SizedBox(height: 10,),
                                TextFormField(
                                    inputFormatters:[
                                      LengthLimitingTextInputFormatter(50)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Apellidos",
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
                                      if(defaultValidator(text)!= null){
                                        return defaultValidator(text, maxLength: 100);
                                      }
                                    },
                                    onChanged: (text)=>setState(() {
                                      surnamesTextEditingContentController.text = text;
                                    })
                                ),
                                SizedBox(height: 10,),

                                DropdownButtonFormField(
                                  decoration: InputDecoration(
                                      hintText: "Tipo de indentificación",
                                      prefixIcon: Icon(Icons.perm_identity, color: darkTheme?Colors.amber.shade400:Colors.grey),
                                      filled: true,
                                      fillColor: darkTheme ? Colors.black45: Colors.grey.shade200,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: BorderSide(
                                              width: 0,
                                              style: BorderStyle.none
                                          )
                                      )
                                  ),
                                  items: indetificationTypes.map((item){
                                    return DropdownMenuItem(
                                      child: Text(
                                        item["text"],
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      value: item["value"].toString(),
                                    );
                                  }).toList(),
                                  onChanged: (newValue){
                                    setState(() {
                                      selectedIndentificationType = newValue.toString();
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Por favor, seleccione un valor para este campo'; // Mensagem de erro se não for selecionada nenhuma opção
                                    }
                                    return null; // Retorne null se a validação for bem-sucedida
                                  },
                                ),
                                SizedBox(height: 10,),
                                TextFormField(
                                    inputFormatters:[
                                      FilteringTextInputFormatter.digitsOnly,
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                      LengthLimitingTextInputFormatter(12)
                                    ],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        hintText: "Numero de identificación",
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
                                        prefixIcon: Icon(Icons.perm_identity_sharp, color: darkTheme? Colors.amber.shade400: Colors.grey,)
                                    ),
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    validator: (text){
                                      if(defaultValidator(text)!= null){
                                        return defaultValidator(text, maxLength: 12);
                                      }
                                    },
                                    onChanged: (text)=>setState(() {
                                      identificationNumberTextEditingContentController.text = text;
                                    })
                                ),
                                SizedBox(height: 10,),
                                TextFormField(
                                    inputFormatters:[
                                      LengthLimitingTextInputFormatter(100)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Correo electrónico",
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
                                      if(defaultValidator(text)!= null){
                                        return defaultValidator(text);
                                      }
                                      if(EmailValidator.validate(text!)==true) return null;
                                    },
                                    onChanged: (text)=>setState(() {
                                      emailTextEditingContentController.text = text;
                                    })
                                ),
                                SizedBox(height: 10,),
                                IntlPhoneField(
                                  showCountryFlag: false,
                                  dropdownIcon: Icon(Icons.arrow_drop_down, color: darkTheme? Colors.amber.shade400: Colors.grey,),
                                  decoration: InputDecoration(
                                    hintText: "Número de teléfono",
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
                                  ),
                                  initialCountryCode: 'VE',
                                  onChanged: (text) => setState(() {
                                    phoneTextEditingContentController.text = text.completeNumber;
                                  }),
                                ),
                                SizedBox(height: 10,),
                                TextFormField(
                                    inputFormatters:[
                                      LengthLimitingTextInputFormatter(100)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Dirección",
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
                                      if(defaultValidator(text, minLength: 5, maxLength: 100)!=null)return defaultValidator(text);
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
                                      hintText: "Contraseña",
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
                                    if(defaultValidator(text)!=null) return defaultValidator(text);
                                  },
                                  onChanged: (text)=>setState(() {
                                    passwordTextEditingContentController.text = text;
                                  }),
                                ),
                                SizedBox(height: 10,),
                                TextFormField(
                                    obscureText: !_passwordVisible,
                                    inputFormatters:[
                                      LengthLimitingTextInputFormatter(100)
                                    ],
                                    decoration: InputDecoration(
                                        hintText: "Confirmar Contraseña",
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
                                      backgroundColor: isSubmitted? Colors.blueGrey.shade200: darkTheme? Colors.amber.shade400:Colors.blue,
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
