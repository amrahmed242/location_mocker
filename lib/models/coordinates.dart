import 'dart:math';

/// A simple class to represent geographical coordinates.
class Coordinates {
  final double latitude;
  final double longitude;
  final double? elevation;
  final double? heading;

  const Coordinates({
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.heading,
  });

  @override
  String toString() {
    return '$longitude,$latitude${elevation != null ? ',$elevation' : ''}${heading != null ? ',$heading' : ''}';
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (elevation != null) 'elevation': elevation,
      if (heading != null) 'heading': heading,
    };
  }

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: json['latitude'],
      longitude: json['longitude'],
      elevation: json['elevation'],
      heading: json['heading'],
    );
  }

  /// Calculates the distance in meters between two coordinates using the Haversine formula
  double distanceTo(Coordinates other) {
    const double earthRadius = 6371000; // Earth radius in meters
    final double lat1Rad = latitude * pi / 180;
    final double lat2Rad = other.latitude * pi / 180;
    final double deltaLatRad = (other.latitude - latitude) * pi / 180;
    final double deltaLonRad = (other.longitude - longitude) * pi / 180;

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}
