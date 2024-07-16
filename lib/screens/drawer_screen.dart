import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/global/global.dart';
import 'package:ven_app/screens/frequent_questions_screen.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/profile_screen.dart';
import 'package:ven_app/screens/terms_and_conditions_screen.dart';
import 'package:ven_app/screens/trip_history_screen.dart';
import 'package:ven_app/widgets/drawer_option.dart';

import '../infoHandler/app_info.dart';

class DrawerScreen extends StatelessWidget {
  const DrawerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      width: 300,
      child: Drawer(
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 50, 0, 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(0),
                      decoration: BoxDecoration(
                          color: Colors.lightBlue,
                          shape: BoxShape.circle
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: AssetImage("images/avatar.png"),
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(86),
                          child:userModelCurrentInfo!.documents['imageSelfie'] != null?
                          Image.network(
                            userModelCurrentInfo!.documents['imageSelfie'],
                            fit: BoxFit.cover,
                            width: 140, // Set the width to the desired size
                            height: 140, // Set the height to the desired size
                          )
                          :
                          Image.asset(
                            "images/avatar.png",
                            fit: BoxFit.cover,
                            width: 140, // Set the width to the desired size
                            height: 140, // Set the height to the desired size
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20,),
                  Center(
                    child: Text(
                    //'user name',
                      "${userModelCurrentInfo!.names!} ${userModelCurrentInfo!.surnames!}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  /*
                  SizedBox(height: 10,),
                  Center(
                    child:
                    GestureDetector(
                      onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (c)=>ProfileScreen())),
                      child: Text(
                        "Editar Perfil",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                   */
                  SizedBox(height: 30,),

                  Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                        Row(
                          children: [
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: darkTheme? Colors.amber.shade400 : Colors.blue,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 5,),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text( '0.0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text( 'Clasificación',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        SizedBox(width: 5,),
                        Row(
                          children: [
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: darkTheme? Colors.amber.shade400 : Colors.blue,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Icon(
                                    Icons.car_repair,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 5,),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text( '0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text( 'Viajes',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                    ],
                  ),
                  ),
                  Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                  DrawerOption(
                    optionName: "Historial de viajes",
                    darkTheme: darkTheme,
                    onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (c)=>TripHistoryScreen())),
                  ),
                  Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                  DrawerOption(
                    optionName: "Preguntas frecuentes",
                    darkTheme: darkTheme,
                    onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (c)=>FrequentQuestionsScreen())),
                  ),
                  Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                  DrawerOption(
                    optionName: "Términos y condiciones",
                    darkTheme: darkTheme,
                    onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (c)=>TermsAndConditionsScreen())),
                  ),
                  Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                  DrawerOption(
                    optionName: "Configuración",
                    darkTheme: darkTheme,
                    onTap: (){},
                  ),
                  Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                  DrawerOption(
                    optionName: "Soporte",
                    darkTheme: darkTheme,
                    onTap: (){},
                  ),
                  Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                ],
              ),

              GestureDetector(
                onTap: (){
                  Provider.of<AppInfo>(context, listen: false).updateToken('');
                  Navigator.push(context, MaterialPageRoute(builder: (c)=>LoginScreen()));
                },
                child: Column(
                  children: [
                    Divider(thickness: 1, color: darkTheme ? Colors.grey : Colors.grey[300],),
                    SizedBox(height: 10,),
                    Text(
                      "Cerrar sesión",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkTheme? Colors.amber.shade400: Colors.blue
                      ),
                    ),
                  ]
                )
              )
            ]
          )

        ),
      ),
    );
  }
}
