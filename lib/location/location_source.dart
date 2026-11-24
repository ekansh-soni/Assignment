import 'package:tracker/models/geo_fix.dart';

abstract class LocationSource {
  Stream<GeoFix> watch();
}
