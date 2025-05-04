[![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)](https://thebsd.github.io/StandWithPalestine)

# location_mocker

A comprehensive Flutter plugin for GPS location mocking, route manipulation, and GPX file handling.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Pub Points](https://img.shields.io/pub/points/location_mocker)
![Pub Version](https://img.shields.io/pub/v/location_mocker)

## Why This Package?

Location Mocker provides a powerful toolset for developers who need to simulate GPS locations and routes in their Flutter applications. Whether you're building navigation apps, fitness trackers, or location-based services, this plugin allows you to:

- Mock GPS locations on Android devices
- Play back GPX routes with customizable speeds
- Plan and manipulate mock routes with deviations
- Import and export GPX files

## Features

- 📍 **GPS Location Mocking**: Simulate GPS locations on Android devices
- 🗺️ **GPX Support**: Parse, create, and manipulate GPX files
- ⚙️ **Route Management**: Add deviations and modify routes programmatically to simulate real life scenarios
- 🔄 **Playback Control**: Start, pause, resume, and stop location simulation
- 🏃‍♂️ **Speed Adjustment**: Modify the playback speed of simulated routes
- 📊 **Location Streaming**: Get real-time updates of the mocked location
- 💾 **GPX Export**: Export routes to GPX files for sharing or storage

## Installation

```yaml
dependencies:
  location_mocker: ^0.0.1
```

## Usage

### Initialize the Plugin

```dart
import 'package:location_mocker/location_mocker.dart';

// Initialize the plugin
await LocationMocker.initialize();

// Check if mock location is enabled in developer settings
bool isMockEnabled = await LocationMocker.isMockLocationEnabled();
if (!isMockEnabled) {
  // Open developer settings to enable mock locations
  await LocationMocker.openMockLocationSettings();
}
```

### Mock Locations with a GPX File

```dart
// Start mocking with a GPX file
await LocationMocker.startMockingWithGpxFile('/path/to/route.gpx', 
  playbackSpeed: 1.5); // 1.5x normal speed

// Update playback speed dynamically
await LocationMocker.updatePlaybackSpeed(2.0); // 2x speed

// Pause mocking
await LocationMocker.pauseMocking();

// Resume mocking
await LocationMocker.resumeMocking();

// Stop mocking
await LocationMocker.stopMocking();
```

### Listen to Location Updates

```dart
// Listen to location updates during mocking
LocationMocker.locationStream.listen((GpxPoint point) {
  print('Current location: ${point.latitude}, ${point.longitude}');
  print('Elevation: ${point.elevation}');
  print('Bearing: ${point.bearing}');
});
```

### Route Manipulation

```dart
import 'package:location_mocker/route_manager/route_manager.dart';
import 'package:location_mocker/models/coordinates.dart';

// Create a route manager with a list of coordinates
final routeManager = RouteDeviationManager([
  Coordinates(lat: 37.7749, lng: -122.4194),
  Coordinates(lat: 37.7750, lng: -122.4190),
  // ... more coordinates
]);

// Add a deviation to the route
await routeManager.addDeviation(
  deviationPointIndex: 5,
  deviationLength: 200,  // meters
  deviationDistance: 50, // meters
  skipDistance: 300,     // meters
);

// Export the modified route as a GPX file
String filePath = await routeManager.exportGpxToFile('my_route');

// Reset route to original state
routeManager.resetRoute();

// Get GPX string representation
String gpxString = routeManager.toGpxString;
```

### Parse GPX Data

```dart
// Parse GPX data into a list of points
String gpxContent = '...'; // GPX file content
List<GpxPoint> points = LocationMocker.parseGpx(gpxContent);

for (var point in points) {
  print('Point: ${point.latitude}, ${point.longitude}');
  if (point.elevation != null) {
    print('Elevation: ${point.elevation} meters');
  }
  if (point.time != null) {
    print('Time: ${point.time}');
  }
}
```

## Platform Support

Currently, this plugin supports the following platforms:

- ✅ Android
- ❌ iOS (Due to iOS restrictions on location mocking)

## Requirements

- Flutter SDK: >= 3.3.0
- Dart SDK: >= 3.1.5
- Android: API level 19+ (Android 4.4+)

## Permissions

This plugin requires the following permissions on Android:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_MOCK_LOCATION" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

## Limitations

- iOS does not support location mocking due to platform restrictions
- Mock locations require developer mode to be enabled on Android devices
- Some Android devices might have specific manufacturer restrictions on location mocking

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

