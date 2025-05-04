// import 'package:flutter_test/flutter_test.dart';
// import 'package:location_mocker/location_mocker.dart';
// import 'package:location_mocker/location_mocker_platform_interface.dart';
// import 'package:location_mocker/location_mocker_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockLocationMockerPlatform
//     with MockPlatformInterfaceMixin
//     implements LocationMockerPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final LocationMockerPlatform initialPlatform = LocationMockerPlatform.instance;

//   test('$MethodChannelLocationMocker is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelLocationMocker>());
//   });

//   test('getPlatformVersion', () async {
//     LocationMocker locationMockerPlugin = LocationMocker();
//     MockLocationMockerPlatform fakePlatform = MockLocationMockerPlatform();
//     LocationMockerPlatform.instance = fakePlatform;

//     expect(await locationMockerPlugin.getPlatformVersion(), '42');
//   });
// }
