import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'location_mocker_platform_interface.dart';

/// An implementation of [LocationMockerPlatform] that uses method channels.
class MethodChannelLocationMocker extends LocationMockerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('location_mocker');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
