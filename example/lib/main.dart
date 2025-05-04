import 'package:flutter/material.dart';
import 'package:location_mocker/location_mocker.dart';
import 'package:location_mocker/models/coordinates.dart';
import 'package:location_mocker/route_manager/route_manager.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocationMocker.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Mocker Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LocationMockerPage(title: 'Location Mocker Demo'),
    );
  }
}

class LocationMockerPage extends StatefulWidget {
  const LocationMockerPage({super.key, required this.title});

  final String title;

  @override
  State<LocationMockerPage> createState() => _LocationMockerPageState();
}

class _LocationMockerPageState extends State<LocationMockerPage> {
  GpxPoint? _currentLocation;
  bool _isMockingEnabled = false;
  bool _isMocking = false;
  double _speed = 1.0;
  String? _routeFilePath;
  RouteDeviationManager? _routeManager;

  @override
  void initState() {
    super.initState();
    _checkMockPermission();
    _setupLocationListener();
  }

  Future<void> _checkMockPermission() async {
    final isEnabled = await LocationMocker.isMockLocationEnabled();
    setState(() {
      _isMockingEnabled = isEnabled;
    });
  }

  void _setupLocationListener() {
    LocationMocker.locationStream.listen((point) {
      setState(() {
        _currentLocation = point;
      });
    });
  }

  Future<void> _openMockSettings() async {
    await LocationMocker.openMockLocationSettings();
    await _checkMockPermission();
  }

  Future<void> _createSampleRoute() async {
    final routeManager = RouteDeviationManager([
      const Coordinates(37.7749, -122.4194),
      const Coordinates(37.7750, -122.4190),
      const Coordinates(37.7755, -122.4185),
      const Coordinates(37.7760, -122.4180),
      const Coordinates(37.7765, -122.4175),
    ]);

    // Add a sample deviation
    await routeManager.addDeviation(
      deviationPointIndex: 2,
      deviationLength: 100,
      deviationDistance: 20,
      skipDistance: 0,
    );

    // Save route to a file
    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        await routeManager.exportGpxToFile('${directory.path}/sample_route');

    setState(() {
      _routeFilePath = filePath;
      _routeManager = routeManager;
    });
  }

  Future<void> _startMocking() async {
    if (_routeFilePath == null) {
      await _createSampleRoute();
    }

    await LocationMocker.startMockingWithGpxFile(_routeFilePath!,
        playbackSpeed: _speed);

    setState(() {
      _isMocking = true;
    });
  }

  Future<void> _pauseMocking() async {
    await LocationMocker.pauseMocking();
    setState(() {
      _isMocking = false;
    });
  }

  Future<void> _resumeMocking() async {
    await LocationMocker.resumeMocking();
    setState(() {
      _isMocking = true;
    });
  }

  Future<void> _stopMocking() async {
    await LocationMocker.stopMocking();
    setState(() {
      _isMocking = false;
    });
  }

  Future<void> _updateSpeed(double speed) async {
    await LocationMocker.updatePlaybackSpeed(speed);
    setState(() {
      _speed = speed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!_isMockingEnabled)
              ElevatedButton(
                onPressed: _openMockSettings,
                child: const Text('Enable Mock Location'),
              ),
            const SizedBox(height: 16),
            Text(
              'Mock Location Status: ${_isMockingEnabled ? "Enabled" : "Disabled"}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Current Location:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_currentLocation != null)
              Text(
                'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}, '
                'Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Text(
                'No location data',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 16),
            Text(
              'Playback Speed: ${_speed.toStringAsFixed(1)}x',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _speed,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              label: '${_speed.toStringAsFixed(1)}x',
              onChanged: (value) {
                _updateSpeed(value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      _isMockingEnabled && !_isMocking ? _startMocking : null,
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _isMocking ? _pauseMocking : _resumeMocking,
                  child: Text(_isMocking ? 'Pause' : 'Resume'),
                ),
                ElevatedButton(
                  onPressed: _isMocking ? _stopMocking : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createSampleRoute,
              child: const Text('Create New Route'),
            ),
          ],
        ),
      ),
    );
  }
}
