import 'package:tracker/data/connectivity_monitor.dart';
import 'package:tracker/data/location_api.dart';
import 'package:tracker/data/location_store.dart';
import 'package:tracker/models/geo_fix.dart';
import 'package:tracker/models/location_record.dart';

class SyncBatchResult {
  const SyncBatchResult({
    required this.synced,
    required this.pending,
    this.error,
    this.offline = false,
    this.alreadyRunning = false,
  });

  final int synced;
  final int pending;
  final String? error;
  final bool offline;
  final bool alreadyRunning;

  bool get failed => error != null;
}

class LocationRepository {
  LocationRepository({
    required this.store,
    required this.api,
    required this.connectivity,
  });

  final LocationStore store;
  final LocationApi api;
  final ConnectivityMonitor connectivity;
  final _ids = _RecordIds();

  var _flushing = false;
  var _again = false;

  Future<List<LocationRecord>> loadAll() => store.all();

  Future<LocationRecord> saveFix(GeoFix fix) async {
    final record = LocationRecord(
      id: _ids.next(),
      latitude: fix.latitude,
      longitude: fix.longitude,
      capturedAt: DateTime.now().toUtc(),
      attemptCount: 0,
      synced: false,
    );
    await store.insert(record);
    return record;
  }

  /// Sends pending rows in capture order.
  ///
  /// A second call while a flush is running does not upload the same row
  /// in parallel. It asks the in-flight flush to look again, so a point
  /// saved mid-sync is still picked up.
  Future<SyncBatchResult> syncPending() async {
    if (_flushing) {
      _again = true;
      final waiting = await store.pending();
      return SyncBatchResult(
        synced: 0,
        pending: waiting.length,
        alreadyRunning: true,
      );
    }

    if (!await connectivity.checkOnline()) {
      final waiting = await store.pending();
      return SyncBatchResult(synced: 0, pending: waiting.length, offline: true);
    }

    _flushing = true;
    var synced = 0;
    String? error;
    var wentOffline = false;
    try {
      do {
        _again = false;
        final step = await _sendPending();
        synced += step.synced;
        error = step.error;
        wentOffline = step.offline;
        if (error != null || wentOffline) break;
      } while (_again && await connectivity.checkOnline());
    } finally {
      _flushing = false;
    }

    final waiting = await store.pending();
    return SyncBatchResult(
      synced: synced,
      pending: waiting.length,
      error: error,
      offline: wentOffline,
    );
  }

  Future<_SendStep> _sendPending() async {
    final batch = await store.pending();
    var synced = 0;
    for (final record in batch) {
      if (!await connectivity.checkOnline()) {
        return _SendStep(synced: synced, offline: true);
      }
      try {
        await api.upload(record);
        await store.markSynced(record.id);
        synced += 1;
      } on LocationApiException catch (error) {
        await store.recordFailedAttempt(record.id);
        return _SendStep(synced: synced, error: error.message);
      } catch (error) {
        await store.recordFailedAttempt(record.id);
        return _SendStep(synced: synced, error: error.toString());
      }
    }
    return _SendStep(synced: synced);
  }
}

class _SendStep {
  const _SendStep({required this.synced, this.error, this.offline = false});

  final int synced;
  final String? error;
  final bool offline;
}

class _RecordIds {
  var _seq = 0;

  String next() {
    _seq += 1;
    final micros = DateTime.now().microsecondsSinceEpoch;
    return '$micros-$_seq';
  }
}
