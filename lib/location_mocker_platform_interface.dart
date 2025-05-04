import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'location_mocker_method_channel.dart';

abstract class LocationMockerPlatform extends PlatformInterface {
  /// Constructs a LocationMockerPlatform.
  LocationMockerPlatform() : super(token: _token);

  static final Object _token = Object();

  static LocationMockerPlatform _instance = MethodChannelLocationMocker();

  /// The default instance of [LocationMockerPlatform] to use.
  ///
  /// Defaults to [MethodChannelLocationMocker].
  static LocationMockerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LocationMockerPlatform] when
  /// they register themselves.
  static set instance(LocationMockerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
