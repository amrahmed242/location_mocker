import 'package:location_mocker/models/coordinates.dart';
import 'package:xml/xml.dart';

extension RouteReader on String {
  List<Coordinates> tryParseRoute() {
    try {
      final document = XmlDocument.parse(this);
      final trackPoints = document.findAllElements('trkpt');

      return trackPoints.map((point) {
        final lat = double.parse(point.getAttribute('lat')!);
        final lon = double.parse(point.getAttribute('lon')!);
        final eleElement = point.findElements('ele').singleOrNull;
        final ele =
            eleElement != null ? double.tryParse(eleElement.innerText) : null;
        final hdgElement = point.findElements('hdg').singleOrNull;
        final hdg =
            hdgElement != null ? double.tryParse(hdgElement.innerText) : null;
        return Coordinates(
          lat,
          lon,
          elevation: ele,
          heading: hdg,
        );
      }).toList();
    } catch (e) {
      throw FormatException('Failed to parse GPX data: $e');
    }
  }
}
