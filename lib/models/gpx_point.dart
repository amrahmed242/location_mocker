/// Represents a point in a GPX track
class GpxPoint {
  final double latitude;
  final double longitude;
  final double? elevation;
  final DateTime? time;
  final double? bearing;

  GpxPoint({
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.time,
    this.bearing,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'bearing': bearing,
      'elevation': elevation,
      'time': time?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'GpxPoint(lat: $latitude, lon: $longitude, ele: $elevation, time: $time)';
  }
}
