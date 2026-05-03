import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Services/supabase_service.dart';

class FutureRidesSearchScreen extends StatefulWidget {
  const FutureRidesSearchScreen({super.key});

  @override
  State<FutureRidesSearchScreen> createState() => _FutureRidesSearchScreenState();
}

class _FutureRidesSearchScreenState extends State<FutureRidesSearchScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRides();
  }

  Future<void> _fetchRides() async {
    setState(() => _isLoading = true);
    final rides = await SupabaseService.getAllFutureRides();
    setState(() {
      _rides = rides;
      _isLoading = false;
    });
  }

  void _bookRide(Map<String, dynamic> ride) async {
    final available = ride['total_seats'] - ride['booked_seats'];
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay puestos disponibles")));
      return;
    }

    int seatsToBook = 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Reservar Puesto"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Viaje: ${ride['origin_address']} ➔ ${ride['destination_address']}"),
              const SizedBox(height: 10),
              Text("Precio: \$${ride['price_per_seat']} por puesto"),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Puestos: "),
                  IconButton(
                    onPressed: seatsToBook > 1 ? () => setState(() => seatsToBook--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text("$seatsToBook", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: seatsToBook < available ? () => setState(() => seatsToBook++) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Text("Total: \$${(seatsToBook * ride['price_per_seat']).toStringAsFixed(2)}"),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirmar Reserva", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final response = await SupabaseService.bookFutureRideSeat(ride['id'], seatsToBook);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reserva exitosa. El conductor se pondrá en contacto contigo.")));
        _fetchRides();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Viajes Compartidos Disponibles"),
        backgroundColor: darkTheme ? Colors.black : Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty
              ? const Center(child: Text("No hay viajes programados por ahora"))
              : RefreshIndicator(
                  onRefresh: _fetchRides,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _rides.length,
                    itemBuilder: (context, index) {
                      final ride = _rides[index];
                      final date = DateTime.parse(ride['ride_date']);
                      final driver = ride['drivers'];
                      final available = ride['total_seats'] - ride['booked_seats'];

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${ride['origin_address']} ➔ ${ride['destination_address']}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    "\$${ride['price_per_seat']}",
                                    style: TextStyle(
                                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Text(DateFormat('dd/MM/yyyy - HH:mm').format(date)),
                                  const SizedBox(width: 15),
                                  const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Text("Disponibles: $available/${ride['total_seats']}"),
                                ],
                              ),
                              const Divider(height: 25),
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: darkTheme ? Colors.amber.shade100 : Colors.blue.shade100,
                                    radius: 20,
                                    child: const Icon(Icons.person),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${driver['names']} ${driver['surnames']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text("Vehículo: ${driver['car_details']['car_model']} (${driver['car_details']['car_color']})", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                              if (ride['description'] != null && ride['description'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(
                                    "Descripción: ${ride['description']}",
                                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                                  ),
                                ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: available > 0 ? () => _bookRide(ride) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                  minimumSize: const Size(double.infinity, 40),
                                ),
                                child: Text(
                                  available > 0 ? "RESERVAR PUESTO" : "AGOTADO",
                                  style: TextStyle(color: darkTheme ? Colors.black : Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
