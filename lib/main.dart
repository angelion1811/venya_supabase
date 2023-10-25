import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/infoHandler/app_info.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/register_screen.dart';
import 'package:ven_app/screens/search_places_screen.dart';
import 'package:ven_app/splashScreen/splash_screen.dart';
import 'package:ven_app/themeProvider/theme_provider.dart';

Future<void> main() async{
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => AppInfo(),
        child:MaterialApp(
          title: 'Flutter Demo',
          themeMode: ThemeMode.system,
          theme: MyThemes.lightTheme,
          darkTheme: MyThemes.darkTheme,
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        ),
    );
  }
}

