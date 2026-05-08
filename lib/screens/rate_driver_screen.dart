import "dart:developer" show log;
import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import '../Services/supabase_service.dart';

/// Pantalla para calificar un viaje existente en Supabase.
/// Esta versión NO crea un nuevo registro, sino que actualiza el existente.
class RateDriverScreen extends StatefulWidget {
  final String? assignedDriverId;
  final String? rideId;

  RateDriverScreen({this.assignedDriverId, this.rideId});

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  double countRatingStarts = 0;
  String titleStartRating = "";
  bool isSaving = false;

  void qualifyDriver(double valueOfStartsChoosed) {
    setState(() {
      countRatingStarts = valueOfStartsChoosed;
      if (countRatingStarts == 1) titleStartRating = "Muy mal";
      if (countRatingStarts == 2) titleStartRating = "Mal";
      if (countRatingStarts == 3) titleStartRating = "Regular";
      if (countRatingStarts == 4) titleStartRating = "Bien";
      if (countRatingStarts == 5) titleStartRating = "Excelente";
    });
  }

  Future<void> saveQualify() async {
    if (countRatingStarts == 0) {
      Fluttertoast.showToast(msg: "Por favor califica tu experiencia primero.");
      return;
    }

    if (widget.assignedDriverId != null && widget.rideId != null) {
      setState(() => isSaving = true);
      
      try {
        // Buscar el ID del viaje en Supabase basado en el rideId (firebase_ride_id)
        final rideData = await SupabaseService.getRideBySupabaseId(widget.rideId!);
        
        String? rideSupabaseId;
        
        if (rideData != null) {
          rideSupabaseId = rideData['id'] as String?;
        }
        
        if (rideSupabaseId != null && rideSupabaseId.isNotEmpty) {
          // Usar el nuevo método para actualizar el rating
          await SupabaseService.updateRideRating(rideSupabaseId, countRatingStarts);
        } else {
          // Fallback al método anterior usando firebase_ride_id
          await SupabaseService.rateDriver(
            widget.assignedDriverId!,
            widget.rideId!,
            countRatingStarts,
          );
        }
      } catch (e) {
        log('Error en saveQualify: $e');
      } finally {
        setState(() => isSaving = false);
      }
    }
    
    Navigator.pop(context, "qualified");
    Fluttertoast.showToast(msg: "Calificado");
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14)
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
            color: darkTheme ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 22,),

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

            const SizedBox(height: 20,),

            SmoothStarRating(
                rating: countRatingStarts,
                allowHalfRating: false,
                starCount: 5,
                color: darkTheme ? Colors.amber.shade400: Colors.blue,
                borderColor: darkTheme ? Colors.amber.shade400: Colors.grey,
                size: 40,
                onRatingChanged: (valueOfStartsChoosed) => qualifyDriver(valueOfStartsChoosed),
            ),

            const SizedBox(height: 10,),

            Text(titleStartRating,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: darkTheme ? Colors.amber.shade400:Colors.blue,
              ),
            ),

            const SizedBox(height: 20,),

            ElevatedButton(
                onPressed: isSaving ? null : () => saveQualify(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                ),
                child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text("Enviar",
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