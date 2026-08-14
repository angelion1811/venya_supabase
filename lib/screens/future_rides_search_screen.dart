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
  List<Map<String, dynamic>> _filteredRides = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

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
      _filteredRides = rides;
      _isLoading = false;
    });
    _filterRides(_searchController.text);
  }

  void _filterRides(String query) {
    if (query.isEmpty) {
      setState(() => _filteredRides = _rides);
    } else {
      final lowercaseQuery = query.toLowerCase();
      setState(() {
        _filteredRides = _rides.where((ride) {
          final origin = ride['origin_address'].toString().toLowerCase();
          final destination = ride['destination_address'].toString().toLowerCase();
          return origin.contains(lowercaseQuery) || destination.contains(lowercaseQuery);
        }).toList();
      });
    }
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

  void _cancelReservation(Map<String, dynamic> ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancelar Reserva"),
        content: const Text("¿Estás seguro de que deseas cancelar tu participación en este viaje compartido?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sí, Cancelar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await SupabaseService.cancelFutureRideReservation(ride['id']);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reserva cancelada correctamente")));
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
        title: const Text("Viajes Compartidos"),
        backgroundColor: darkTheme ? Colors.black : Colors.blue,
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              onChanged: _filterRides,
              decoration: InputDecoration(
                hintText: "Buscar por origen o destino...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterRides("");
                      },
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: darkTheme ? Colors.grey.shade900 : Colors.grey.shade100,
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRides.isEmpty
                     ? const Center(child: Text("No se encontraron viajes"))
                     : RefreshIndicator(
                        onRefresh: _fetchRides,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: _filteredRides.length,
                          itemBuilder: (context, index) {
                            final ride = _filteredRides[index];
                            final date = DateTime.parse(ride['ride_date']);
                            final driver = ride['users'];
                            final available = ride['total_seats'] - ride['booked_seats'];
                            final isUserPassenger = ride['is_user_passenger'] ?? false;
                            final userSeats = ride['user_booked_seats'] ?? 0;

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
                                    if (isUserPassenger)
                                      Container(
                                        margin: const EdgeInsets.only(top: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                            const SizedBox(width: 5),
                                            Text("Tengo $userSeats puestos reservados", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
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
                                    if (isUserPassenger)
                                      ElevatedButton(
                                        onPressed: () => _cancelReservation(ride),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade400,
                                          minimumSize: const Size(double.infinity, 40),
                                        ),
                                        child: const Text(
                                          "CANCELAR RESERVA",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    else
                                      ElevatedButton(
                                        onPressed: available > 0 ? () => _bookRide(ride) : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                          disabledBackgroundColor: Colors.grey,
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
          ),
        ],
      ),
    );
  }
}
