import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:ven_app/models/directions.dart';
import 'package:ven_app/models/trips_history_model.dart';

class AppInfo extends ChangeNotifier{
    Directions? userPickUpLocation, userDropOffLocation;
    int countTotalTrips = 0;
    List<String> historyTripsKeysList = [];
    List<TripsHistoryModel>  allTripsHistoryInformationList = [];

    void updatePickUpLocationAddress(Directions userPickUpAddress){
      userPickUpLocation = userPickUpAddress;
      notifyListeners();
    }

    void updateDroffLocationAddress(Directions dropOffAddress){
      userDropOffLocation = dropOffAddress;
      notifyListeners();
    }

    updateOverAllTripsCounter(int overAllTripsCounter){
      countTotalTrips = overAllTripsCounter;
      notifyListeners();
    }

    updateOverAllTripsKeys(List<String> tripsKeysList){
      historyTripsKeysList = tripsKeysList;
      notifyListeners();
    }

    updateOverAllTripsHistoryInformation(TripsHistoryModel eachTripModel){
      allTripsHistoryInformationList.add(eachTripModel);
      notifyListeners();
    }
}