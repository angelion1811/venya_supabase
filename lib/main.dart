import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ven_app/infoHandler/app_info.dart';
import 'package:ven_app/screens/login_screen.dart';
import 'package:ven_app/screens/register_screen.dart';
import 'package:ven_app/screens/search_places_screen.dart';
import 'package:ven_app/splashScreen/splash_screen.dart';
import 'package:ven_app/themeProvider/theme_provider.dart';
import 'package:ven_app/widgets/pay_fare_amount_dialog.dart';
import 'package:ven_app/screens/change_password_screen.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inicializar Supabase - Reemplaza con tus credenciales de Supabase
  await Supabase.initialize(
    url: 'https://ygkpfkzapqlnggpagbcy.supabase.co',
    anonKey: 'sb_publishable_4dwFLn5RYjWtFCQuDCaqJA_R7h_zXda',
  );

  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => AppInfo(),
        child:MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Venya',
          themeMode: ThemeMode.system,
          theme: MyThemes.lightTheme,
          darkTheme: MyThemes.darkTheme,
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        ),
    );
  }
}

