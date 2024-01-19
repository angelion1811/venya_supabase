import 'package:flutter/material.dart';

GestureDetector CardVehicleType(
{
  String selectedVehicleType ='',
  void Function()? onTap,
  bool darkTheme= false,
  String assetImageString = "",
  double assetImageScale = 1,
  String vehicleTypeString = "",
  String amountString = ""
}
    ){
    return GestureDetector(
      onTap: onTap,
      child: Container(
          decoration: BoxDecoration(
            color: selectedVehicleType == vehicleTypeString? (darkTheme?Colors.amber.shade400:Colors.blue):(darkTheme?Colors.black54:Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(25.0),
            child: Column(
              children: [
                Image.asset(assetImageString, scale: assetImageScale,),
                SizedBox( height: 8,),
                Text(
                 vehicleTypeString,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selectedVehicleType == vehicleTypeString? (darkTheme?Colors.black:Colors.white):(darkTheme?Colors.white:Colors.black),
                  ),
                ),
                SizedBox(height: 2,),
                Text(amountString,
                    style: TextStyle(
                        color: Colors.grey
                    )
                )
              ],
            ),
          )
      ),
    );
}

