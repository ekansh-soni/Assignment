import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityMonitor {
  Future<bool> checkOnline();

  Stream<bool> watch();

  /// Demo override. While this is on, [checkOnline] stays false even if
  /// the phone has a connection.
  void setForceOffline(bool value);
}

class DeviceConnectivityMonitor implements ConnectivityMonitor {
  DeviceConnectivityMonitor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  var _forceOffline = false;

  @override
  void setForceOffline(bool value) {
    _forceOffline = value;
  }

  @override
  Future<bool> checkOnline() async {
    if (_forceOffline) return false;
    final results = await _connectivity.checkConnectivity();
    return _hasNetwork(results);
  }

  @override
  Stream<bool> watch() {
    return _connectivity.onConnectivityChanged.map(_hasNetwork);
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.other,
    );
  }
}
