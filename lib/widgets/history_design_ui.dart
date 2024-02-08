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
            color: darkTheme ?Colors.red:Colors.white,
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
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.person, color: Colors.white),
                      ),

                      SizedBox(width: 15,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.tripsHistoryModel!.driverName!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 8,),

                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.orange, ),

                              SizedBox(width: 5,),

//                          Text(widget.tripsHistoryModel!.ratings!)
                              Text("4,5",
                                style: TextStyle(
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
              SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(2)
                        ),
                        child: Icon(Icons.star, color: Colors.white,),
                      ),
                      SizedBox(width: 15,),
                      Text(displayHistoryLocationString(widget.tripsHistoryModel!.originAddress!),
                        textAlign: TextAlign.justify,
                      )
                    ],
                  )
                ],
              ),
              SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2)
                        ),
                        child: Icon(Icons.star, color: Colors.white,),
                      ),
                      SizedBox(width: 15,),
                      Text(displayHistoryLocationString(widget.tripsHistoryModel!.destinationAddress!),
                          textAlign: TextAlign.justify,
                      )
                    ],
                  )
                ],
              )
            ],
          ),
        )

      ],
    );
  }
}
