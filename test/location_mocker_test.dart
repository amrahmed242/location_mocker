import 'package:flutter_test/flutter_test.dart';
import 'package:location_mocker/location_mocker_method_channel.dart';
import 'package:location_mocker/location_mocker_platform_interface.dart';

void main() {
  final LocationMockerPlatform initialPlatform =
      LocationMockerPlatform.instance;

  test('$MethodChannelLocationMocker is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLocationMocker>());
  });
}
