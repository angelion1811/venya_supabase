import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ven_app/Assistants/request_assistant.dart';
import 'package:ven_app/Services/supabase_service.dart';
import 'package:ven_app/models/predicted_places.dart';
import 'package:ven_app/widgets/place_prediction_tile.dart';

class SearchPlacesScreen extends StatefulWidget {
  String? place;
  SearchPlacesScreen({this.place});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {

  List<PredictedPlaces> placesPredictedList = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  findPlaceAutoComplete(String inputText) async {
    if(inputText.length > 1){
      setState(() {
        isLoading = true;
      });
      // Nominatim requiere User-Agent header - usamos el email del usuario autenticado
      final userEmail = SupabaseService.currentUser?.email ?? 'anonimo@venapp.com';
      String urlAutoCompleteSearch = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(inputText)}&limit=20&format=json&addressdetails=1';
      
      var responseApiAutoCompleteSearch = await RequestAssistant.receiveRequest(
        urlAutoCompleteSearch,
        headers: {
          'User-Agent': 'VenApp/1.0 ($userEmail)', 
        },
      );

      setState(() {
        isLoading = false;
      });

      if(responseApiAutoCompleteSearch == "Error Ocurred. Failed. No Response."){
        return;
      }

      if(responseApiAutoCompleteSearch != null && responseApiAutoCompleteSearch is List){
        var placePredictionsList = (responseApiAutoCompleteSearch as List).map((jsonData) => PredictedPlaces.fromJson(jsonData)).toList();
        setState(() { placesPredictedList = placePredictionsList; });
      }
    } else {
      setState(() {
        placesPredictedList = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: darkTheme? Colors.black: Colors.white,
        appBar: AppBar(
          backgroundColor: darkTheme? Colors.amber.shade400: Colors.blue,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back, color: darkTheme? Colors.black:Colors.white,),
          ),
          title: Text(
            "Buscar Sitio",
            style: TextStyle(color: darkTheme ? Colors.black: Colors.white),
          ),
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: darkTheme? Colors.amber.shade400: Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white54,
                    blurRadius: 8,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7)
                  )
                ]
            ),
              child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    children:[
                      Row(
                          children:[
                            Icon(
                              Icons.adjust_sharp,
                              color: darkTheme? Colors.black: Colors.white,
                            ),
                            SizedBox(width: 10.0,),
                            Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value){
                                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                                      _debounce = Timer(const Duration(milliseconds: 2000), () {
                                        findPlaceAutoComplete(value);
                                      });
                                    },
                                    decoration: InputDecoration(
                                        hintText: "Buscar localización...",
                                        fillColor: darkTheme ? Colors.black: Colors.white54,
                                        filled: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: EdgeInsets.only(left: 11, top: 8, bottom: 8),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if(_searchController.text.isNotEmpty)
                                              IconButton(
                                                icon: Icon(Icons.clear, color: darkTheme ? Colors.black : Colors.white),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() => placesPredictedList = []);
                                                },
                                              ),
                                            IconButton(
                                              icon: Icon(Icons.search, color: darkTheme ? Colors.black : Colors.white),
                                              onPressed: () {
                                                _debounce?.cancel();
                                                findPlaceAutoComplete(_searchController.text);
                                              },
                                            ),
                                          ],
                                        )
                                    ),
                                  ),
                                )
                            ),
                          ]
                      )
                    ]
                  ),
              ),
            ),

            if (isLoading)
              LinearProgressIndicator(
                color: darkTheme ? Colors.black : Colors.blue,
                backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.white,
              ),

            if (!isLoading && _searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Resultados encontrados: ${placesPredictedList.length}",
                  style: TextStyle(
                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // display place prediction result
            Expanded(
              child: placesPredictedList.length > 0 
                ? ListView.separated(
                    itemCount: placesPredictedList.length,
                    physics: ClampingScrollPhysics(),
                    itemBuilder: (context, index){
                      return PlacePredictionTileDesign(
                        predictedPlaces: placesPredictedList[index],
                        place: widget.place,
                      );
                    },
                    separatorBuilder: (BuildContext context, int index){
                      return Divider(
                        height: 1,
                        color: darkTheme? Colors.amber.shade400: Colors.blue,
                        thickness: 0.5,
                      );
                    },
                  )
                : Center(
                    child: _searchController.text.length > 1 && !isLoading
                        ? Text("No se encontraron resultados", style: TextStyle(color: Colors.grey))
                        : Container(),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
