class FareHourMultiplier {
  final String id;
  final String vehicleTypeId;
  final String startTime;
  final String endTime;
  final double multiplier;
  final bool isActive;

  FareHourMultiplier({
    required this.id,
    required this.vehicleTypeId,
    required this.startTime,
    required this.endTime,
    required this.multiplier,
    required this.isActive,
  });

  factory FareHourMultiplier.fromJson(Map<String, dynamic> json) {
    return FareHourMultiplier(
      id: json['id'] as String,
      vehicleTypeId: json['vehicle_type_id'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_type_id': vehicleTypeId,
      'start_time': startTime,
      'end_time': endTime,
      'multiplier': multiplier,
      'is_active': isActive,
    };
  }

  /// Verifica si la hora actual (HH:MM) cae dentro de este intervalo.
  /// Soporta intervalos nocturnos donde startTime > endTime (ej: 22:30 a 06:00).
  bool isCurrentTimeInRange() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = _timeToMinutes(startTime);
    final endMinutes = _timeToMinutes(endTime);

    if (startMinutes <= endMinutes) {
      // Intervalo normal: ej 06:00 a 18:00
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Intervalo nocturno: ej 22:30 a 06:00
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  /// Convierte un string de tiempo "HH:MM" o "HH:MM:SS" a minutos totales desde medianoche.
  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = parts.length > 1 ? int.parse(parts[1]) : 0;
    return hours * 60 + minutes;
  }
}
