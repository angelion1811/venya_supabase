import 'package:flutter/material.dart';

GestureDetector DrawerOption(
    {
      String optionName ='',
      void Function()? onTap,
      bool darkTheme = false,
    }
    ){
      return GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: Column(
            children: [
              const SizedBox(height: 10,),
              Text(optionName,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: darkTheme? Colors.amber.shade400: Colors.blue
                ),),
              const SizedBox(height: 10,),
            ],
          ),
        ),
      );
    }