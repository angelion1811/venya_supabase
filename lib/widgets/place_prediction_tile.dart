import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/infoHandler/app_info.dart';
import 'package:ven_app/models/predicted_places.dart';
import 'package:ven_app/widgets/progress_dialog.dart';

import '../models/directions.dart';

class PlacePredictionTileDesign extends StatefulWidget {
  //const PlacePredictionTileDesign({Key? key}) : super(key: key);

  final PredictedPlaces? predictedPlaces;
  final String? place;

  PlacePredictionTileDesign({this.predictedPlaces, this.place});

  @override
  State<PlacePredictionTileDesign> createState() => _PlacePredictionTileDesignState();
}

class _PlacePredictionTileDesignState extends State<PlacePredictionTileDesign> {

  getPlaceDirectionDetails(PredictedPlaces? cPredictedPlaces, String? placeId, context) async {
    if(cPredictedPlaces == null || cPredictedPlaces.latitude == null || cPredictedPlaces.longitude == null){
      Fluttertoast.showToast(msg: "Error: Ubicación inválida");
      return;
    }

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
          message: "Configurando ubicación, por favor espere....",
        )
    );
    print('cPredictedPlaces');
    print(cPredictedPlaces.place_id);

    Directions directions = Directions();
    directions.locationName = cPredictedPlaces.secondary_text ?? cPredictedPlaces.main_text ?? 'Ubicación';
    directions.locationId = cPredictedPlaces.place_id ?? '';
    directions.locationLatitude = cPredictedPlaces.latitude;
    directions.locationLongitude = cPredictedPlaces.longitude;

    Navigator.pop(context);

    if(widget.place != null) {
      if(widget.place == 'origin') {
        Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(
            directions);

        Navigator.pop(context, "obtainedPickup");
      } else {
        Provider.of<AppInfo>(context, listen: false).updateDroffLocationAddress(
            directions);
        setState(() {
          userDropOffAddress = directions.locationName ?? '';
        });

        Navigator.pop(context, "obtainedDropoff");
      }
    }
    /*
    String placeDirectionDetailUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&keys=$mapKey";

    var responseApi = await RequestAssistant.receiveRequest(placeDirectionDetailUrl);
    
    Navigator.pop(context);
    if(responseApi == "Error Ocurred. Failed. No Response."){
      return;
    }

    if(responseApi['status'] == "Ok"){
      Directions directions = Directions();
      directions.locationName = responseApi["result"]["name"];
      directions.locationId = placeId;
      directions.locationLatitude = responseApi["result"]["geometry"]["location"]["lat"];
      directions.locationLongitude = responseApi["result"]["geometry"]["location"]["lng"];
      Provider.of<AppInfo>(context, listen: false).updateDroffLocationAddress(directions);
      setState(() {
        userDropOffAddress = directions.locationName!;
      });

      Navigator.pop(context, "obtainedDropoff");
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Manejar caso de datos nulos
    final place = widget.predictedPlaces;
    if (place == null) {
      return SizedBox.shrink();
    }

    return ElevatedButton(
        onPressed: (){
          getPlaceDirectionDetails(place, place.place_id, context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: darkTheme? Colors.black: Colors.white
        ),
        child: Padding(
          padding: EdgeInsets.all(0.0),
          child: Row(
            children: [
              Icon(
                  Icons.add_location,
                  color: darkTheme? Colors.amber.shade400: Colors.blue,
              ),
              SizedBox(width: 10,),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.main_text ?? 'Sin nombre',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: darkTheme? Colors.amber.shade400 : Colors.blue,
                    )
                  ),
                  Text(
                      place.secondary_text ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: darkTheme? Colors.grey.shade400 : Colors.grey,
                      )
                  )
                ],
              ))
            ]
          ),
        )
    );
  }
}
