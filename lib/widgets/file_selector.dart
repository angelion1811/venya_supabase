import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

FileSelector({
  XFile? xFile,
  String label ="",
  void Function()? onTap,
}){
  return GestureDetector(
    onTap: onTap,
    child:
      Column(
      children: [
        xFile == null?
            Container(
              child: CircleAvatar(
                radius: 70,
                backgroundImage: AssetImage("images/avatar.png"),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(86),
                  child: Image.asset(
                    "images/avatar.png",
                    fit: BoxFit.cover,
                    width: 140, // Set the width to the desired size
                    height: 140, // Set the height to the desired size
                  ),
                ),
              ),
            )
            :
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
                image: DecorationImage(
                  fit: BoxFit.fitHeight,
                  image:FileImage(File(xFile!.path))
                )
              ),
            ),
          const SizedBox(height: 10,),

           Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
  );
}