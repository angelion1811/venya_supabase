import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/infoHandler/app_info.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/widgets/file_selector.dart';

import '../Services/supabase_service.dart';
import '../models/user_model.dart';
import '../splashScreen/splash_screen.dart';

class RegisterDocumentsScreen extends StatefulWidget {
  const RegisterDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<RegisterDocumentsScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterDocumentsScreen> {

  XFile?  imageSelfie,
          imageDocument,
          imageSelfieWithDocument;

  String  urlOfUploadedImageSelfie = "",
          urlOfUploadedImageDocument = "",
          urlOfUploadedImageSelfieWithDocument = "";

  bool isSubmitted = false;
  //declare global key
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    //validate field of form;

    if(_formKey.currentState!.validate()){
      try {

      Map<String, dynamic> documents = {
        "imageSelfie": urlOfUploadedImageSelfie,
        "imageDocument": urlOfUploadedImageDocument,
        "imageSelfieWithDocument": urlOfUploadedImageSelfieWithDocument,
      };

      dynamic res = await SupabaseService.addUserDocuments(documents);
      print("result put registerUser");
      print('res.statusCode');
      await Fluttertoast.showToast(msg: "Estatus: ${res['statusCode']}");
      if(res['statusCode'] == 400) {
        var errors = res['errors'] as Map<String, dynamic>;
        for (String key in errors.keys) {
          for (String value in errors[key]) {
            await Fluttertoast.showToast(msg: "$key: ${value}");
          }
        }
        setState(()=> isSubmitted = false);
      } else if(res['statusCode'] == 201){
        log("Documentos guardados");
        await Fluttertoast.showToast(msg: "Documentos de Indetificacion guardados, Felicitaciones");
        Navigator.push(context, MaterialPageRoute(builder: (c)=>SplashScreen()));
      } else if(res['statusCode'] == 401){
        Provider.of<AppInfo>(context, listen: false).updateToken('');
        Navigator.push(context, MaterialPageRoute(builder: (c)=>SplashScreen()));
      } else {
        await Fluttertoast.showToast(msg: "Estatus: ${res['statusCode']}");
        setState(()=> isSubmitted = false);
      }
      } catch(e){
        log('Error: $e');
        Fluttertoast.showToast(msg: "error aca  $e.message");
        setState(()=> isSubmitted = false);
      }

    } else {
      Fluttertoast.showToast(msg: "No todos los campos esta llenos");
      setState(()=> isSubmitted = false);
    }

  }


  chooseImageFromGallery(int typeOfFile) async {
    final ImagePicker picker = ImagePicker();
    // Pick an image.
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
    //final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(pickedFile != null){
      switch(typeOfFile){
        case 1:
          setState(() =>imageSelfie = pickedFile);
          break;
        case 2:
          setState(() =>imageDocument = pickedFile);
          break;
        case 3:
          setState(() =>imageSelfieWithDocument = pickedFile);
          break;
      }
    }
  }

  Future<String> uploadImageToStorage(XFile? xFile, String documentType) async {
    if (xFile == null) return '';

    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    String fileName = '${documentType}_$imageIDName.jpg';

    final result = await SupabaseService.uploadFile(
      file: File(xFile.path),
      bucketName: 'user-documents',
      folderPath: 'documents',
      fileName: fileName,
    );

    if (result['success'] == true) {
      return result['url'] as String;
    } else {
      throw Exception(result['message'] ?? 'Error al subir imagen');
    }
  }

  uploadImagesToStorage() async {
    setState(()=> isSubmitted = true);
    log("asdkfanbsjkba");
    if(imageSelfie == null) {
      Fluttertoast.showToast(msg: "Por favor, tomarse una foto");
      setState(()=> isSubmitted = false);
      return;
    }

    if(imageDocument == null) {
      Fluttertoast.showToast(msg: "Por favor, tomar una foto al documento de identidad");
      setState(()=> isSubmitted = false);
      return;
    }

    if(imageSelfieWithDocument == null) {
      Fluttertoast.showToast(msg: "Por favor, tomarse una foto con el documento de indetidad");
      setState(()=> isSubmitted = false);
      return;
    }

    try{
      urlOfUploadedImageSelfie  = await uploadImageToStorage(imageSelfie, 'selfie');
      print("Selfie subida exitosamente");
      urlOfUploadedImageDocument =  await uploadImageToStorage(imageDocument, 'document');
      urlOfUploadedImageSelfieWithDocument = await uploadImageToStorage(imageSelfieWithDocument, 'selfie_with_document');
      Fluttertoast.showToast(msg: "Foto de perfil con documento de identidad cargada");
      setState((){
        urlOfUploadedImageSelfie;
        urlOfUploadedImageDocument;
        urlOfUploadedImageSelfieWithDocument;
      });

      _submit();

    } catch(e){
      log('Error: $e');
      Fluttertoast.showToast(msg: "error to storage $e");
      setState(()=> isSubmitted = false);
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
          SizedBox(height: 10,),

          Center(child:Text("Registro De Documentos",
            style: TextStyle(
              color: darkTheme? Colors.amber.shade400: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ) ,),),
          SizedBox( height: 10,),
          FileSelector(
            xFile: imageSelfie,
            onTap: (){
              chooseImageFromGallery(1);
            },
            label: "Elige una foto de perfil"
          ),
          SizedBox( height: 10,),
          FileSelector(
              xFile: imageDocument,
              onTap: (){
                chooseImageFromGallery(2);
              },
              label: "Elige una foto del documento de identidad"
          ),
          SizedBox( height: 10,),
          FileSelector(
              xFile: imageSelfieWithDocument,
              onTap: (){
                chooseImageFromGallery(3);
              },
              label: "Toma una foto de perfil \n con el documento de identidad"
          ),
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
                                  SizedBox(height: 20,),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: isSubmitted? Colors.blueGrey.shade100: darkTheme? Colors.amber.shade400:Colors.blue,
                                          foregroundColor: darkTheme? Colors.black:Colors.white,
                                          elevation: 50,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          minimumSize: Size(double.infinity, 50)
                                      ),
                                      onPressed: (){
                                        isSubmitted?null:uploadImagesToStorage();
                                      },
                                      child: Text('Registrar Documentos',
                                        style: TextStyle(fontSize: 20),
                                      ),

                                                                        ),
                                  SizedBox(height: 20,),
                                ],
                            ),
                    ),
                  ])
              ),
        ]),
      ));
  }
}
