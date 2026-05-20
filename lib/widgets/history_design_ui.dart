import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ven_app/Helpers/custom_functions.dart';
import 'package:ven_app/models/trips_history_model.dart';

class HistoryDesignUIWidget extends StatefulWidget {

  TripsHistoryModel? tripsHistoryModel;

  HistoryDesignUIWidget({this.tripsHistoryModel});
  @override
  State<HistoryDesignUIWidget> createState() => _HistoryDesignUIWidgetState();
}

class _HistoryDesignUIWidgetState extends State<HistoryDesignUIWidget> {

  String formatDateAndTime(String dateTimeFromDB){
    DateTime dateTime = DateTime.parse(dateTimeFromDB);

    String formattedDateTime = "${DateFormat.MMMd().format(dateTime)}, ${DateFormat.y().format(dateTime)} - ${DateFormat.jm().format(dateTime)}";
    return formattedDateTime;
  }
  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formatDateAndTime(widget.tripsHistoryModel!.time!),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 10,),

        Container(
          decoration: BoxDecoration(
            color: darkTheme ?Colors.black:Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue,
                          borderRadius: BorderRadius.circular(12),
                          image: widget.tripsHistoryModel?.driverPhoto != null && widget.tripsHistoryModel!.driverPhoto!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(widget.tripsHistoryModel!.driverPhoto!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.tripsHistoryModel?.driverPhoto == null || widget.tripsHistoryModel!.driverPhoto!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 30)
                            : null,
                      ),

                      SizedBox(width: 15,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mostrar nombre y apellido del conductor separados
                          _buildNameDisplay(widget.tripsHistoryModel!.driverName ?? "Conductor", darkTheme),
                          SizedBox(height: 8,),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.orange, ),
                              SizedBox(width: 5,),
                              // Si no tiene rating, mostrar "Sin calificar" con badge
                              if (widget.tripsHistoryModel!.ratings == null || widget.tripsHistoryModel!.ratings!.isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "Sin calificar",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Text(widget.tripsHistoryModel!.ratings!,
                                  style: const TextStyle(
                                    color: Colors.grey
                                  )
                                )
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Costo Final",
                        style: TextStyle(
                            color: Colors.grey
                        ),
                      ),

                      SizedBox(height: 8,),

                      Text(" ${widget.tripsHistoryModel!.fareAmount!}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,

                        ),
                      )
                    ],


                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Estatus",
                        style: TextStyle(
                            color: Colors.grey
                        ),
                      ),

                      SizedBox(height: 8,),

                      Text(" ${widget.tripsHistoryModel!.status!}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,

                        ),
                      )
                    ],


                  )
                ],
              ),
              SizedBox(height: 10,),
              Divider(thickness: 3, color: Colors.grey[200],),
              SizedBox(height: 10,),
              Row(
                children: [
                  Text("Viaje",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ]
              ),
              // Mostrar origen solo si NO es viaje de agua
              if (widget.tripsHistoryModel!.waterLiters == null || widget.tripsHistoryModel!.waterLiters!.isEmpty) ...[
                SizedBox(height: 10,),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(2)
                      ),
                      child: Icon(Icons.star, color: Colors.white, size: 16),
                    ),
                    SizedBox(width: 15,),
                    Expanded(
                      child: Text(widget.tripsHistoryModel!.originAddress!,
                        style: TextStyle(
                          fontSize: 14,
                          color: darkTheme ? Colors.grey[300] : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 10,),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2)
                    ),
                    child: Icon(Icons.star, color: Colors.white, size: 16),
                  ),
                  SizedBox(width: 15,),
                  Expanded(
                    child: Text(widget.tripsHistoryModel!.destinationAddress!,
                      style: TextStyle(
                        fontSize: 14,
                        color: darkTheme ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.tripsHistoryModel!.waterLiters != null && widget.tripsHistoryModel!.waterLiters!.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 10,),
                    Row(
                      children: [
                        Icon(Icons.water_drop, color: Colors.blue[600], size: 18),
                        const SizedBox(width: 15,),
                        Text(
                          "Cantidad: ${widget.tripsHistoryModel!.waterLiters!} Litros",
                          style: TextStyle(
                            fontSize: 14,
                            color: darkTheme ? Colors.grey[300] : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 10,),
            ],
          ),
        )

      ],
    );
  }

  Widget _buildNameDisplay(String fullName, bool isDarkTheme) {
    // Separar nombre y apellido
    final parts = fullName.trim().split(' ');
    String firstName = "";
    String lastName = "";

    if (parts.isNotEmpty) {
      firstName = parts[0];
    }
    if (parts.length > 1) {
      // Tomar solo el primer apellido
      lastName = parts[1];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firstName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (lastName.isNotEmpty)
          Text(
            lastName,
            style: TextStyle(
              fontSize: 12,
              color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
      ],
    );
  }
}
