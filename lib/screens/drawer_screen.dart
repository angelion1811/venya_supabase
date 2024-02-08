import 'package:flutter/material.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/profile_screen.dart';
import 'package:ven_app/screens/trip_history_screen.dart';

class DrawerScreen extends StatelessWidget {
  const DrawerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: Drawer(
        child: Padding(
          padding: EdgeInsets.fromLTRB(30, 50, 0, 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children:[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        shape: BoxShape.circle
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 20,),

                  Text(
                    //'user name',
                    "${userModelCurrentInfo!.name!}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10,),
                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (c)=>ProfileScreen()));
                    },
                    child: Text(
                      "Editar Perfil",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  SizedBox(height: 30,),

                  GestureDetector(
                      onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (c)=> TripHistoryScreen()));
                      },
                      child: Text("Tus Viajes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),)
                  ),
                  SizedBox(height: 15,),

                  Text("Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                  SizedBox(height: 15,),

                  Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                  SizedBox(height: 15,),

                  Text("Promos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                  SizedBox(height: 15,),

                  Text("Help", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                  SizedBox(height: 15,),

                  Text("Free Trips", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                  SizedBox(height: 15,),

                ],
              ),
              GestureDetector(
                onTap: (){
                  firebaseAuth.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c)=>LoginScreen()));
                },
                child: Text(
                    "Log out",
                    style: TextStyle(
                      fontWeight: FontWeight.bold
                    ),
                ),
              )
            ]
          )

        ),
      ),
    );
  }
}
