import 'package:location_mocker/models/coordinates.dart';
import 'package:xml/xml.dart';

/// Extension method that converts a list of Coordinates into a GPX file string.
extension RouteConverter on List<Coordinates> {
  String toGPX() {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('gpx', nest: () {
      builder.attribute('version', '1.1');
      builder.attribute('creator', 'RouteDeviationManager');
      builder.attribute('xmlns', 'http://www.topografix.com/GPX/1/1');
      builder.attribute(
          'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
      builder.attribute('xsi:schemaLocation',
          'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd');

      builder.element('trk', nest: () {
        builder.element('name', nest: 'Generated Route');
        builder.element('trkseg', nest: () {
          for (final coord in this) {
            builder.element('trkpt', nest: () {
              builder.attribute('lat', coord.latitude.toString());
              builder.attribute('lon', coord.longitude.toString());
              if (coord.elevation != null) {
                builder.element('ele', nest: coord.elevation.toString());
              }
              if (coord.heading != null) {
                builder.element('hdg', nest: coord.heading.toString());
              }
            });
          }
        });
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }
}
