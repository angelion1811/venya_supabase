import 'dart:developer';
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:ven_app/infoHandler/app_info.dart";
import "package:ven_app/Services/supabase_service.dart";
import "package:ven_app/models/trips_history_model.dart";
import "package:ven_app/widgets/history_design_ui.dart";
import "rate_driver_screen.dart";

class TripHistoryScreen extends StatefulWidget {
  final bool showUnratedOnly;

  TripHistoryScreen({Key? key, this.showUnratedOnly = false}) : super(key: key);

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<TripsHistoryModel> unratedRidesList = [];
  bool isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.showUnratedOnly) {
      _loadUnratedRides();
    }
  }

  Future<void> _loadUnratedRides() async {
    setState(() => isLoading = true);
    try {
      final rides = await SupabaseService.getUnratedRides();
      unratedRidesList = rides
          .map<TripsHistoryModel>((ride) => TripsHistoryModel.fromJson(ride))
          .toList();
    } catch (e) {
      log('Error cargando viajes sin calificar: $e');
      _errorText = "Error al cargar viajes sin calificar";
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showRateDialog(int index, TripsHistoryModel model) {
    // Usar el ID de Supabase (uuid) para calificar el viaje existente
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => RateDriverScreen(
        assignedDriverId: model.driverName ?? "", // Driver name como identificador
        rideId: model.id ?? "", // ID de Supabase (UUID) del viaje - califica el registro existente
      ),
    ).then((value) {
      if (value == "qualified") {
        _loadUnratedRides(); // Recargar la lista después de calificar
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final displayList = widget.showUnratedOnly
        ? unratedRidesList
        : Provider.of<AppInfo>(context, listen: false).allTripsHistoryInformationList;

    return Scaffold(
      backgroundColor: darkTheme? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: darkTheme? Colors.black: Colors.white,
        title: Text(
          widget.showUnratedOnly ? "Viajes por Calificar" : "Historial de Viajes",
          style: TextStyle(
            color: darkTheme ? Colors.amber.shade400 : Colors.black
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: darkTheme ? Colors.amber.shade400 : Colors.black),
          onPressed: (){
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorText != null
          ? Center(child: Text(_errorText!, style: TextStyle(color: Colors.red)))
          : displayList.isEmpty
            ? Center(
                child: Text(
                  widget.showUnratedOnly
                    ? "No tienes viajes pendientes por calificar"
                    : "No tienes viajes en el historial",
                  style: TextStyle(
                    color: darkTheme ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              )
            : Padding(
                padding: EdgeInsets.all(20),
                child: ListView.separated(
                  itemBuilder: (context, i) {
                    final trip = displayList[i];
                    // Verificar si el viaje ya tiene calificación
                    final bool hasRating = trip.ratings != null && trip.ratings!.isNotEmpty;

                    return GestureDetector(
                      onTap: () {
                        // Permite calificar si: showUnratedOnly=true O el viaje no tiene calificación
                        if (widget.showUnratedOnly || !hasRating) {
                          _showRateDialog(i, trip);
                        }
                      },
                      child: Card(
                        color: darkTheme ? Colors.black : Colors.grey[100],
                        shadowColor: Colors.transparent,
                        child: HistoryDesignUIWidget(
                          tripsHistoryModel: trip,
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, i) => const SizedBox(height: 30,),
                  itemCount: displayList.length,
                  physics: const ClampingScrollPhysics(),
                  shrinkWrap: true,
                ),
              ),
    );
  }
}
