import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:location_mocker/models/gpx_point.dart';
import 'package:xml/xml.dart';

import 'location_mocker_platform_interface.dart';

class LocationMocker {
  static final LocationMockerPlatform _platform =
      LocationMockerPlatform.instance;

  /// Initialize the location mocker plugin
  static Future<bool> initialize() => _platform.initialize();

  /// Check if mock location is enabled in developer options
  static Future<bool> isMockLocationEnabled() =>
      _platform.isMockLocationEnabled();

  /// Start location mocking with GPX data
  /// [gpxData] - String content of the GPX file
  /// [playbackSpeed] - Speed multiplier for location updates (1.0 = normal speed)
  static Future<bool> startMockingWithGpx(String gpxData,
      {double playbackSpeed = 1.0}) {
    return _platform.startMockingWithGpx(gpxData, playbackSpeed: playbackSpeed);
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
  static Future<bool> updatePlaybackSpeed(double playbackSpeed) {
    return _platform.updatePlaybackSpeed(playbackSpeed);
  }

  /// Stop location mocking
  static Future<bool> stopMocking() => _platform.stopMocking();

  /// Open mock location settings on Android
  static Future<bool> openMockLocationSettings() =>
      _platform.openMockLocationSettings();

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
  static Future<bool> pauseMocking() => _platform.pauseMocking();

  /// Resume location mocking from current position
  static Future<bool> resumeMocking() => _platform.resumeMocking();

  /// Stream of location updates during mocking
  static Stream<GpxPoint> get locationStream => _platform.getLocationStream();
}
