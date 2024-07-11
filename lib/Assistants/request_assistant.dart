import "dart:convert";

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../infoHandler/app_info.dart';

class RequestAssistant{

  static String _baseUrl ='https://venya-backend.vercel.app';
  //static String _baseUrl ='https://venya-backend.onrender.com';
  //static String _baseUrl ='https://6639wp30-3000.use.devtunnels.ms/';

  static Future<dynamic> receiveRequest(String url) async {
    http.Response httpResponse = await http.get(Uri.parse(url));

    try{
      if(httpResponse.statusCode == 200){ //exito
        String responseData = httpResponse.body;
        var decodeResponseData = jsonDecode(responseData);
        return decodeResponseData;
      }
      else {
        return "Error Ocurred. Failed. No Response.";
      }
    } catch(exp){
      return "Error Ocurred. Failed. No Response.";
    }

  }

 static Future<http.Response> registerUser(userData) {
   return http.post(
     Uri.parse('$_baseUrl/api/user/register'),
     headers: <String, String>{
       'Content-Type': 'application/json; charset=UTF-8',
       // 'Authorization': 'Bearer ${authController.token}',
       'Accept': 'application/json;'
     },
     body: jsonEncode(userData),
   );
  }

  static Future<http.Response> loginUser(userData) {
    return http.post(
      Uri.parse('$_baseUrl/api/user/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        // 'Authorization': 'Bearer ${authController.token}',
        'Accept': 'application/json;'
      },
      body: jsonEncode(userData),
    );
  }

  static Future<http.Response> addUserDocuments(String token, data) {
    return http.put(
      Uri.parse('$_baseUrl/api/user/register/documents'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': '${token}',
        'Accept': 'application/json;',
      },
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> getProfile(String token) {
    return http.get(
      Uri.parse('$_baseUrl/api/user/profile'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': '${token}',
        'Accept':'application/json;'
      },
    );
  }

  static Future<http.Response> saveRide(String token, data) {
    print("saveRide ${data}");
    return http.post(
      Uri.parse('$_baseUrl/api/ride'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': '${token}',
        'Accept': 'application/json;',
      },
      body: jsonEncode(data),
    );
  }
}