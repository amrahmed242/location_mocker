import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:location_mocker/extensions/rotue_converter.dart';
import 'package:location_mocker/models/coordinates.dart';
import 'package:retry/retry.dart';

/// Manages geographical routes and provides functionality to add deviations
/// and export to GPX format.
class RouteDeviationManager {
  /// The original, unmodified route
  final ValueNotifier<List<Coordinates>> _originalRoute;

  /// The current route with any applied deviations
  final ValueNotifier<List<Coordinates>> _currentRoute;

  /// A record of all applied deviations for tracking purposes
  final ValueNotifier<List<Map<String, dynamic>>> _appliedDeviations;

  /// OSRM API base URL
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  /// HTTP client for API requests
  final http.Client _httpClient = http.Client();

  /// Retry configuration for API requests
  final RetryOptions _retryOptions = const RetryOptions(
    delayFactor: Duration(seconds: 2),
    maxDelay: Duration(seconds: 10),
    maxAttempts: 3,
  );

  /// Creates a RouteDeviationManager with the given original route.
  RouteDeviationManager(List<Coordinates> originalRoute)
      : _originalRoute = ValueNotifier(List.from(originalRoute)),
        _currentRoute = ValueNotifier(List.from(originalRoute)),
        _appliedDeviations = ValueNotifier([]) {
    if (originalRoute.isEmpty) {
      throw ArgumentError('Original route cannot be empty');
    }
  }

  /// Returns a copy of the current route.
  List<Coordinates> getCurrentRoute() {
    return List.from(_currentRoute.value);
  }

  /// Resets the route to its original state, removing all deviations.
  void resetRoute() {
    _currentRoute.value = List.from(_originalRoute.value);
    _appliedDeviations.value.clear();
  }

  /// Converts the current route to a GPX string.
  String get toGpxString {
    return _currentRoute.value.toGPX();
  }

  /// Exports the current route as a GPX file to device storage.
  /// Returns the path to the exported file.
  Future<String> exportGpxToFile([String? fileName]) async {
    try {
      final String? directoryPath = await getDownloadDirectoryPath();
      if (directoryPath == null) {
        throw Exception('Failed to get download directory path');
      }
      final String filePath =
          '$directoryPath/${fileName ?? 'route_${DateTime.now().millisecondsSinceEpoch}'}.gpx';
      final File file = File(filePath);
      await file.writeAsString(_currentRoute.value.toGPX());
      return filePath;
    } catch (e) {
      throw Exception('Failed to export GPX file: $e');
    }
  }

  /// Adds a deviation to the route at the specified index with the given parameters.
  /// Returns a Future<bool> indicating whether the deviation was successfully applied.
  Future<bool> addDeviation({
    required int deviationPointIndex,
    required double deviationLength,
    required double deviationDistance,
    required double skipDistance,
  }) async {
    // Validate input parameters
    if (deviationPointIndex < 0 ||
        deviationPointIndex >= _currentRoute.value.length - 1) {
      throw RangeError('Deviation point index out of bounds');
    }

    if (deviationLength <= 0 || deviationDistance <= 0 || skipDistance <= 0) {
      throw ArgumentError('Deviation parameters must be positive values');
    }

    // Find the starting point of the deviation
    final startPoint = _currentRoute.value[deviationPointIndex];

    // Find the approximate reconnection point based on skipDistance
    int reconnectionIndex = deviationPointIndex;
    double accumulatedDistance = 0.0;

    while (reconnectionIndex < _currentRoute.value.length - 1 &&
        accumulatedDistance < skipDistance) {
      accumulatedDistance += _currentRoute.value[reconnectionIndex]
          .distanceTo(_currentRoute.value[reconnectionIndex + 1]);
      reconnectionIndex++;
    }

    if (reconnectionIndex >= _currentRoute.value.length - 1) {
      reconnectionIndex = _currentRoute.value.length - 1;
    }

    final reconnectionPoint = _currentRoute.value[reconnectionIndex];

    // Calculate a deviation path using OSRM
    try {
      final deviationPath = await _calculateDeviationPath(
        startPoint: startPoint,
        endPoint: reconnectionPoint,
        deviationDistance: deviationDistance,
        deviationLength: deviationLength,
      );

      if (deviationPath.isEmpty) {
        return false;
      }

      // Apply the deviation to the current route
      _currentRoute.value = [
        ..._currentRoute.value.sublist(0, deviationPointIndex),
        ...deviationPath,
        ..._currentRoute.value.sublist(reconnectionIndex + 1),
      ];

      // Record the applied deviation
      _appliedDeviations.value.add({
        'deviationPointIndex': deviationPointIndex,
        'deviationLength': deviationLength,
        'deviationDistance': deviationDistance,
        'skipDistance': skipDistance,
        'appliedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Failed to add deviation: $e');
      return false;
    }
  }

  /// Calculates a deviation path using the OSRM API.
  Future<List<Coordinates>> _calculateDeviationPath({
    required Coordinates startPoint,
    required Coordinates endPoint,
    required double deviationDistance,
    required double deviationLength,
  }) async {
    // Generate waypoints for the OSRM API request
    final List<Coordinates> waypoints = _generateDeviationWaypoints(
      startPoint: startPoint,
      endPoint: endPoint,
      deviationDistance: deviationDistance,
      deviationLength: deviationLength,
    );

    // Construct the coordinates string for the OSRM API
    final String coordinates =
        waypoints.map((coord) => coord.toString()).join(';');

    // Construct the OSRM API request URL
    final String url =
        '$_osrmBaseUrl/route/v1/driving/$coordinates?overview=full&geometries=geojson';

    try {
      // Make the API request with retry logic
      final response = await _retryOptions.retry(
        () => _httpClient
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10)),
        retryIf: (e) => e is TimeoutException || e is SocketException,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'OSRM API request failed with status code: ${response.statusCode}');
      }

      // Parse the response
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['code'] != 'Ok') {
        throw Exception('OSRM API returned error: ${data['message']}');
      }

      // Extract the route geometry (coordinates) from the response
      final List<dynamic> routeGeometry =
          data['routes'][0]['geometry']['coordinates'];

      // Convert the coordinates to GeoCoordinates objects
      return routeGeometry.map((coord) {
        return Coordinates(
          coord[0],
          coord[1],
          // OSRM doesn't provide elevation data
          elevation: null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to calculate deviation path: $e');
    }
  }

  /// Generates waypoints for the deviation path based on the parameters.
  List<Coordinates> _generateDeviationWaypoints({
    required Coordinates startPoint,
    required Coordinates endPoint,
    required double deviationDistance,
    required double deviationLength,
  }) {
    // Calculate the direct bearing from start to end point
    final double directBearing = _calculateBearing(startPoint, endPoint);

    // Calculate a perpendicular bearing for maximum deviation
    final double deviationBearing = (directBearing + 90) % 360;

    // Calculate the mid-point location for deviation
    final double midDistance = deviationLength / 2;
    final Coordinates midPoint = _calculateDestination(
      startPoint,
      directBearing,
      midDistance,
    );

    // Calculate the deviation point
    final Coordinates deviationPoint = _calculateDestination(
      midPoint,
      deviationBearing,
      deviationDistance,
    );

    // Return the waypoints for the OSRM API
    return [startPoint, deviationPoint, endPoint];
  }

  /// Calculates the bearing in degrees from point 1 to point 2.
  double _calculateBearing(Coordinates point1, Coordinates point2) {
    final double lat1 = point1.latitude * pi / 180;
    final double lat2 = point2.latitude * pi / 180;
    final double lon1 = point1.longitude * pi / 180;
    final double lon2 = point2.longitude * pi / 180;

    final double y = sin(lon2 - lon1) * cos(lat2);
    final double x =
        cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);

    final double bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  /// Calculates a destination point given a starting point, bearing, and distance.
  Coordinates _calculateDestination(
    Coordinates startPoint,
    double bearing,
    double distance,
  ) {
    const double earthRadius = 6371000; // Earth radius in meters
    final double bearingRad = bearing * pi / 180;
    final double lat1Rad = startPoint.latitude * pi / 180;
    final double lon1Rad = startPoint.longitude * pi / 180;
    final double angularDistance = distance / earthRadius;

    final double lat2Rad = asin(sin(lat1Rad) * cos(angularDistance) +
        cos(lat1Rad) * sin(angularDistance) * cos(bearingRad));

    final double lon2Rad = lon1Rad +
        atan2(sin(bearingRad) * sin(angularDistance) * cos(lat1Rad),
            cos(angularDistance) - sin(lat1Rad) * sin(lat2Rad));

    return Coordinates(
      lat2Rad * 180 / pi,
      lon2Rad * 180 / pi,
      elevation: startPoint.elevation,
    );
  }

  /// Cleans up resources when the manager is no longer needed.
  void dispose() {
    _httpClient.close();
  }
}
