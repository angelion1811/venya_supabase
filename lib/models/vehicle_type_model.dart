class VehicleType {
  final String id;
  final String key;
  final String name;
  final String? description;
  final String? iconName;
  final double fareMultiplier;
  final bool hasCustomFare;
  final bool isActive;
  final int displayOrder;
  final List<dynamic>? extraFields;

  VehicleType({
    required this.id,
    required this.key,
    required this.name,
    this.description,
    this.iconName,
    required this.fareMultiplier,
    required this.hasCustomFare,
    required this.isActive,
    required this.displayOrder,
    this.extraFields,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      fareMultiplier: (json['fare_multiplier'] as num?)?.toDouble() ?? 1.0,
      hasCustomFare: json['has_custom_fare'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      extraFields: json['extra_fields'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'fare_multiplier': fareMultiplier,
      'has_custom_fare': hasCustomFare,
      'is_active': isActive,
      'display_order': displayOrder,
      'extra_fields': extraFields,
    };
  }
}