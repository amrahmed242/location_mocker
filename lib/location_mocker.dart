import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

class LocationMocker {
  static const MethodChannel _channel = MethodChannel('location_mocker');
  static const EventChannel _eventChannel =
      EventChannel('location_mocker_events');

  /// Initialize the location mocker plugin
  static Future<bool> initialize() async {
    try {
      final bool result = await _channel.invokeMethod('initialize');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to initialize: ${e.message}');
      return false;
    }
  }

  /// Check if mock location is enabled in developer options
  static Future<bool> isMockLocationEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isMockLocationEnabled');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to check mock location status: ${e.message}');
      return false;
    }
  }

  /// Start location mocking with GPX data
  /// [gpxData] - String content of the GPX file
  /// [playbackSpeed] - Speed multiplier for location updates (1.0 = normal speed)
  static Future<bool> startMockingWithGpx(String gpxData,
      {double playbackSpeed = 1.0}) async {
    try {
      final result = await _channel.invokeMethod('startMockingWithGpx', {
        'gpxData': gpxData,
        'playbackSpeed': playbackSpeed,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to start mocking: ${e.message}');
      return false;
    }
  }

  /// Start location mocking with GPX file
  /// [gpxFilePath] - Path of the GPX file
  /// [playbackSpeed] - Speed multiplier for location updates (1.0 = normal speed)
  static Future<bool> startMockingWithGpxFile(String gpxFilePath,
      {double playbackSpeed = 1.0}) async {
    try {
      final file = File(gpxFilePath);
      if (!await file.exists()) {
        throw Exception('GPX file not found');
      }

      final gpxData = await file.readAsString();
      return startMockingWithGpx(gpxData, playbackSpeed: playbackSpeed);
    } catch (e) {
      debugPrint('Failed to read GPX file: $e');
      return false;
    }
  }

  /// Update the playback speed during mocking
  /// [playbackSpeed] - Speed multiplier for location updates (1.0 = normal speed)
  static Future<bool> updatePlaybackSpeed(double playbackSpeed) async {
    try {
      final result = await _channel.invokeMethod('updatePlaybackSpeed', {
        'playbackSpeed': playbackSpeed,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to update playback speed: ${e.message}');
      return false;
    }
  }

  /// Stop location mocking
  static Future<bool> stopMocking() async {
    try {
      final result = await _channel.invokeMethod('stopMocking');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop mocking: ${e.message}');
      return false;
    }
  }

  static Future<bool> openMockLocationSettings() async {
    try {
      final result = await _channel.invokeMethod('openMockLocationSettings');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to open settings: ${e.message}');
      return false;
    }
  }

  /// Parse GPX data and return list of coordinates
  static List<GpxPoint> parseGpx(String gpxData) {
    final points = <GpxPoint>[];

    try {
      final document = XmlDocument.parse(gpxData);
      final trkpts = document.findAllElements('trkpt');

      for (final trkpt in trkpts) {
        final lat = double.tryParse(trkpt.getAttribute('lat') ?? '0');
        final lon = double.tryParse(trkpt.getAttribute('lon') ?? '0');
        final bearing = double.tryParse(trkpt.getAttribute('bearing') ?? '0');

        if (lat == null || lon == null) continue;

        // Try to get elevation and time
        String? elevStr = trkpt.findElements('ele').firstOrNull?.innerText;
        String? timeStr = trkpt.findElements('time').firstOrNull?.innerText;

        double? elevation = elevStr != null ? double.tryParse(elevStr) : null;
        DateTime? time = timeStr != null ? DateTime.tryParse(timeStr) : null;

        points.add(GpxPoint(
          latitude: lat,
          longitude: lon,
          bearing: bearing,
          elevation: elevation,
          time: time,
        ));
      }
    } catch (e) {
      debugPrint('Failed to parse GPX: $e');
    }

    return points;
  }

  /// Pause location mocking (keeping current position)
  static Future<bool> pauseMocking() async {
    try {
      final result = await _channel.invokeMethod('pauseMocking');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to pause mocking: ${e.message}');
      return false;
    }
  }

  /// Resume location mocking from current position
  static Future<bool> resumeMocking() async {
    try {
      final result = await _channel.invokeMethod('resumeMocking');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to resume mocking: ${e.message}');
      return false;
    }
  }

  /// Stream of location updates during mocking
  static Stream<GpxPoint> get locationStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(event);
      return GpxPoint(
        latitude: data['latitude'],
        longitude: data['longitude'],
        elevation: data['elevation'],
        time: data['time'] != null ? DateTime.parse(data['time']) : null,
        bearing: data['bearing'],
      );
    });
  }
}

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
