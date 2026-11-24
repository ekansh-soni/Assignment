import 'package:flutter/material.dart';
import 'package:tracker/app.dart';
import 'package:tracker/data/connectivity_monitor.dart';
import 'package:tracker/data/location_api.dart';
import 'package:tracker/data/location_repository.dart';
import 'package:tracker/data/location_store.dart';
import 'package:tracker/location/simulated_location_source.dart';
import 'package:tracker/tracking/tracking_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = await SqliteLocationStore.open();
  final api = MockLocationApi();
  final connectivity = DeviceConnectivityMonitor();
  final repository = LocationRepository(
    store: store,
    api: api,
    connectivity: connectivity,
  );
  final cubit = TrackingCubit(
    repository: repository,
    connectivity: connectivity,
    locations: SimulatedLocationSource(),
    api: api,
  );
  await cubit.init();

  runApp(DriverTrackerApp(cubit: cubit));
}
