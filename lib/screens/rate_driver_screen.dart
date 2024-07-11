import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/splashScreen/splash_screen.dart';

class RateDriverScreen extends StatefulWidget {

  String? assignedDriverId;
  RateDriverScreen({this.assignedDriverId});

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    qualifyDriver(double valueOfStartsChoosed) {
      print("qualifyDriver $valueOfStartsChoosed $countRatingStarts");
      countRatingStarts = valueOfStartsChoosed;
      if(countRatingStarts == 1){
        setState(()=>titleStartRating = "Muy mal");
      }
      if(countRatingStarts == 2){
        setState(()=>titleStartRating = "Muy mal");
      }
      if(countRatingStarts == 3){
        setState(()=>titleStartRating = "Muy mal");
      }
      if(countRatingStarts == 4){
        setState(()=>titleStartRating = "Muy mal");
      }
      if(countRatingStarts == 5){
        setState(()=>titleStartRating = "Muy mal");
      }
    }

    saveQualify(){

      Navigator.pop(context, "qualified");
      Fluttertoast.showToast(msg: "Calificado");

    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14)
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
            color: darkTheme ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 22,),

            Text("calificar experiencia",
              style: TextStyle(
                fontSize: 22,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: darkTheme? Colors.amber.shade400: Colors.blue,
              ),
            ),
            Text("de viaje",
              style: TextStyle(
                fontSize: 22,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: darkTheme? Colors.amber.shade400: Colors.blue,
              ),
            ),

            Divider(thickness:2, color: darkTheme? Colors.amber.shade400 : Colors.blue),

            SizedBox(height: 20,),

            SmoothStarRating(
                rating: countRatingStarts,
                allowHalfRating: false,
                starCount: 5,
                color: darkTheme ? Colors.amber.shade400: Colors.blue,
                borderColor: darkTheme ? Colors.amber.shade400: Colors.grey,
                size: 40,
                onRatingChanged: (valueOfStartsChoosed)=>qualifyDriver(valueOfStartsChoosed),
            ),

            SizedBox(height: 10,),

            Text(titleStartRating,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: darkTheme ? Colors.amber.shade400:Colors.blue,
              ),
            ),

            SizedBox(height: 20,),

            ElevatedButton(
                onPressed: ()=>saveQualify(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                ),
                child: Text("Enviar",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkTheme ? Colors.black : Colors.white
                  ),
                )
            )
          ],
        ),
      ),
    );
  }
}
