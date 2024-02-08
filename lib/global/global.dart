import 'package:firebase_auth/firebase_auth.dart';
import 'package:ven_app/models/direction_details_info.dart';
import 'package:ven_app/models/user_model.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;

UserModel? userModelCurrentInfo;

String cloudMessagingServerToken = "key=AAAAM_1iEKQ:APA91bEZeGcE-2cUqWJVQ11pk0CKHjoabwWQClD6Krl9GGOLHRA6QtVR16b7mPHb4_EPdaLimrVx_kz2s0UtGwCX8A7IEtbAvTsSTbqf7qo8G1B8100437dle_rPEKZH09K9lKCQinpc";
List driversList = [];
DirectionDetailsInfo? tripDirectionDetailsInfo;
String userDropOffAddress = "";
String driverCarDetails = "";
String driverName = "";
String driverPhone = "";
String driverRatings = "";

double countRatingStarts = 0.0;
String titleStartRating = "";



