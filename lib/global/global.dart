import 'package:firebase_auth/firebase_auth.dart';
import 'package:ven_app/models/direction_details_info.dart';
import 'package:ven_app/models/user_model.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;

UserModel? userModelCurrentInfo;

DirectionDetailsInfo? tripDirectionDetailsInfo;
String userDropOffAddress = "";