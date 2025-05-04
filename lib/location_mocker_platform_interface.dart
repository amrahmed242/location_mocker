import 'dart:async';

import 'package:location_mocker/models/gpx_point.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'location_mocker_method_channel.dart';

abstract class LocationMockerPlatform extends PlatformInterface {
  /// Constructs a LocationMockerPlatform.
  LocationMockerPlatform() : super(token: _token);

  static final Object _token = Object();

  static LocationMockerPlatform _instance = MethodChannelLocationMocker();

  static LocationMockerPlatform get instance => _instance;

  static set instance(LocationMockerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<bool> isMockLocationEnabled() {
    throw UnimplementedError(
        'isMockLocationEnabled() has not been implemented.');
  }

  Future<bool> startMockingWithGpx(String gpxData,
      {double playbackSpeed = 1.0}) {
    throw UnimplementedError('startMockingWithGpx() has not been implemented.');
  }

  Future<bool> updatePlaybackSpeed(double playbackSpeed) {
    throw UnimplementedError('updatePlaybackSpeed() has not been implemented.');
  }

  Future<bool> stopMocking() {
    throw UnimplementedError('stopMocking() has not been implemented.');
  }

  Future<bool> openMockLocationSettings() {
    throw UnimplementedError(
        'openMockLocationSettings() has not been implemented.');
  }

  Future<bool> pauseMocking() {
    throw UnimplementedError('pauseMocking() has not been implemented.');
  }

  Future<bool> resumeMocking() {
    throw UnimplementedError('resumeMocking() has not been implemented.');
  }

  Stream<GpxPoint> getLocationStream() {
    throw UnimplementedError('getLocationStream() has not been implemented.');
  }
}
