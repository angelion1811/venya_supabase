import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:ven_app/models/directions.dart';

class AppInfo extends ChangeNotifier{
    Directions? userPickUpLocation, userDropOffLocation;
    int countTotalTrips = 0;
    //List<String> historyTripsKeysList = [];
    //List<TripsHistoryModel>  allTripsHistoryInformationList = [];

    void updatePickUpLocationAddress(Directions userPickUpAddress){
      userPickUpLocation = userPickUpAddress;
      notifyListeners();
    }

    void updateDroffLocationAddress(Directions dropOffAddress){
      userDropOffLocation = dropOffAddress;
      notifyListeners();
    }
}