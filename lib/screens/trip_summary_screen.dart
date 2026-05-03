import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import '../Services/supabase_service.dart';

class TripSummaryScreen extends StatefulWidget {
  final String? assignedDriverId;
  final String? rideId;
  final String? driverName;
  final double? fareAmount;
  final String? originAddress;
  final String? destinationAddress;

  TripSummaryScreen({
    this.assignedDriverId,
    this.rideId,
    this.driverName,
    this.fareAmount,
    this.originAddress,
    this.destinationAddress,
  });

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  double countRatingStarts = 0;
  String titleStartRating = "";

  void qualifyDriver(double valueOfStartsChoosed) {
    setState(() {
      countRatingStarts = valueOfStartsChoosed;
      if (countRatingStarts == 1) {
        titleStartRating = "Muy mal";
      } else if (countRatingStarts == 2) {
        titleStartRating = "Mal";
      } else if (countRatingStarts == 3) {
        titleStartRating = "Regular";
      } else if (countRatingStarts == 4) {
        titleStartRating = "Bien";
      } else if (countRatingStarts == 5) {
        titleStartRating = "Excelente";
      }
    });
  }

  Future<void> saveQualify() async {
    if (widget.assignedDriverId != null && widget.rideId != null && countRatingStarts > 0) {
      await SupabaseService.rateDriver(
          widget.assignedDriverId!,
          widget.rideId!,
          countRatingStarts
      );
      Fluttertoast.showToast(msg: "Calificación enviada. ¡Gracias!");
      Navigator.pop(context, "qualified");
    } else if (countRatingStarts == 0) {
      Fluttertoast.showToast(msg: "Por favor califica tu experiencia primero.");
    } else {
      Navigator.pop(context, "qualified");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    Color primaryColor = darkTheme ? Colors.amber.shade400 : Colors.blue;

    return Scaffold(
      backgroundColor: darkTheme ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          "Resumen del Viaje",
          style: TextStyle(
            color: darkTheme ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false, // Prevent back button
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              // Icon or Image for completion
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              SizedBox(height: 10),
              Text(
                "¡Has llegado a tu destino!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkTheme ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 30),

              // Trip Details Card
              Container(
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Driver Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Icon(Icons.person, color: primaryColor, size: 30),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Conductor",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                widget.driverName ?? "Desconocido",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: darkTheme ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300),
                    SizedBox(height: 20),
                    
                    // Route Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.my_location, color: Colors.blue, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Origen",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                widget.originAddress ?? "No especificado",
                                style: TextStyle(
                                  color: darkTheme ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Destino",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                widget.destinationAddress ?? "No especificado",
                                style: TextStyle(
                                  color: darkTheme ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300),
                    SizedBox(height: 20),
                    
                    // Fare Info
                    Text(
                      "Tarifa Final",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "\$ ${widget.fareAmount?.toStringAsFixed(2) ?? '0.00'}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 40,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Rating Section
              Text(
                "¿Cómo estuvo tu viaje?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkTheme ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 15),
              SmoothStarRating(
                rating: countRatingStarts,
                allowHalfRating: false,
                starCount: 5,
                color: primaryColor,
                borderColor: Colors.grey,
                size: 45,
                onRatingChanged: (valueOfStartsChoosed) => qualifyDriver(valueOfStartsChoosed),
              ),
              SizedBox(height: 10),
              Text(
                titleStartRating,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: primaryColor,
                ),
              ),
              
              SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => saveQualify(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    "Confirmar Pago y Calificar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkTheme ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
