import 'dart:async';

import 'package:tracker/location/location_source.dart';
import 'package:tracker/models/geo_fix.dart';

/// Walks a fixed route so the demo does not depend on a GPS fix.
///
/// Swap this for a geolocator-backed [LocationSource] when running on a device
/// that should report the real position. The rest of the app only sees [GeoFix].
class SimulatedLocationSource implements LocationSource {
  SimulatedLocationSource({this.interval = const Duration(seconds: 3)});

  final Duration interval;

  /// Short drive around India Gate, New Delhi.
  static const route = <GeoFix>[
    GeoFix(28.6143, 77.1990),
    GeoFix(28.6134, 77.2055),
    GeoFix(28.6129, 77.2140),
    GeoFix(28.6128, 77.2215),
    GeoFix(28.6129, 77.2294),
    GeoFix(28.6148, 77.2308),
    GeoFix(28.6180, 77.2260),
    GeoFix(28.6195, 77.2185),
    GeoFix(28.6188, 77.2095),
    GeoFix(28.6165, 77.2020),
  ];

  @override
  Stream<GeoFix> watch() async* {
    var index = 0;
    while (true) {
      yield route[index % route.length];
      index += 1;
      await Future<void>.delayed(interval);
    }
  }
}
