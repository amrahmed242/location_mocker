import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:location_mocker/models/gpx_point.dart';

import 'location_mocker_platform_interface.dart';

/// An implementation of [LocationMockerPlatform] that uses method channels.
class MethodChannelLocationMocker extends LocationMockerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('location_mocker');

  @visibleForTesting
  final eventChannel = const EventChannel('location_mocker_events');

  @override
  Future<bool> initialize() async {
    try {
      final bool result = await methodChannel.invokeMethod('initialize');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to initialize: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> isMockLocationEnabled() async {
    try {
      final bool result =
          await methodChannel.invokeMethod('isMockLocationEnabled');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to check mock location status: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> startMockingWithGpx(String gpxData,
      {double playbackSpeed = 1.0}) async {
    try {
      final result = await methodChannel.invokeMethod('startMockingWithGpx', {
        'gpxData': gpxData,
        'playbackSpeed': playbackSpeed,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to start mocking: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> updatePlaybackSpeed(double playbackSpeed) async {
    try {
      final result = await methodChannel.invokeMethod('updatePlaybackSpeed', {
        'playbackSpeed': playbackSpeed,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to update playback speed: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> stopMocking() async {
    try {
      final result = await methodChannel.invokeMethod('stopMocking');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop mocking: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> openMockLocationSettings() async {
    try {
      final result =
          await methodChannel.invokeMethod('openMockLocationSettings');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to open settings: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> pauseMocking() async {
    try {
      final result = await methodChannel.invokeMethod('pauseMocking');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to pause mocking: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> resumeMocking() async {
    try {
      final result = await methodChannel.invokeMethod('resumeMocking');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to resume mocking: ${e.message}');
      return false;
    }
  }

  @override
  Stream<GpxPoint> getLocationStream() {
    return eventChannel.receiveBroadcastStream().map((event) {
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
