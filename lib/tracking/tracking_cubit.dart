import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracker/data/connectivity_monitor.dart';
import 'package:tracker/data/location_api.dart';
import 'package:tracker/data/location_repository.dart';
import 'package:tracker/location/location_source.dart';
import 'package:tracker/models/geo_fix.dart';
import 'package:tracker/tracking/tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit({
    required this.repository,
    required this.connectivity,
    required this.locations,
    required this.api,
    this.retryDelay = const Duration(seconds: 3),
  }) : super(const TrackingState());

  final LocationRepository repository;
  final ConnectivityMonitor connectivity;
  final LocationSource locations;
  final LocationApi api;
  final Duration retryDelay;

  StreamSubscription<GeoFix>? _fixes;
  StreamSubscription<bool>? _connectivitySub;
  Timer? _retry;
  var _work = Future<void>.value();

  Future<void> init() async {
    final online = await connectivity.checkOnline();
    final records = await repository.loadAll();
    if (isClosed) return;
    emit(
      state.copyWith(isOnline: online, records: records, clearMessage: true),
    );
    _connectivitySub = connectivity.watch().listen(_onConnectivity);
    if (online) {
      await _sync();
    }
  }

  Future<void> start() async {
    if (state.isTracking) return;
    emit(state.copyWith(isTracking: true, clearMessage: true));
    _fixes = locations.watch().listen((fix) {
      _work = _work.then((_) => _handleFix(fix));
    });
  }

  Future<void> stop() async {
    await _fixes?.cancel();
    _fixes = null;
    if (isClosed) return;
    emit(state.copyWith(isTracking: false));
  }

  Future<void> setForceOffline(bool value) async {
    connectivity.setForceOffline(value);
    final online = await connectivity.checkOnline();
    if (isClosed) return;
    emit(state.copyWith(forceOffline: value, isOnline: online));
    if (online) {
      _retry?.cancel();
      await _sync();
    }
  }

  Future<void> setRejectUploads(bool value) async {
    final client = api;
    if (client is MockLocationApi) {
      client.rejectUploads = value;
    }
    if (isClosed) return;
    emit(state.copyWith(rejectUploads: value));
    if (!value && state.isOnline) {
      _retry?.cancel();
      await _sync();
    }
  }

  void _onConnectivity(bool online) {
    // The offline switch is a local override. Ignore radio updates while it is on.
    if (isClosed || state.forceOffline) return;
    emit(state.copyWith(isOnline: online));
    if (online) {
      _retry?.cancel();
      _sync();
    }
  }

  Future<void> _handleFix(GeoFix fix) async {
    if (isClosed) return;
    await repository.saveFix(fix);
    if (isClosed) return;
    await _sync();
  }

  Future<void> _sync() async {
    if (isClosed) return;
    emit(state.copyWith(isSyncing: true));
    final result = await repository.syncPending();
    if (isClosed) return;
    final records = await repository.loadAll();
    if (isClosed) return;

    if (result.alreadyRunning) {
      emit(state.copyWith(records: records));
      return;
    }

    final failed = result.failed;
    emit(
      state.copyWith(
        records: records,
        isSyncing: false,
        statusMessage: failed
            ? 'Upload failed. Saved on this phone and will retry.'
            : null,
        clearMessage: !failed,
      ),
    );

    if (failed && state.isOnline && !state.forceOffline) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(retryDelay, () {
      if (isClosed) return;
      _sync();
    });
  }

  @override
  Future<void> close() async {
    _retry?.cancel();
    await _fixes?.cancel();
    await _connectivitySub?.cancel();
    return super.close();
  }
}
