import 'package:tracker/models/location_record.dart';

abstract class LocationApi {
  Future<void> upload(LocationRecord record);
}

class LocationApiException implements Exception {
  LocationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Stand-in for `POST /driver/locations`.
///
/// [acceptedIds] is the server-side set. Posting an id that is already
/// accepted is a success and does not create a second point.
class MockLocationApi implements LocationApi {
  /// When true, every upload fails. Used by the demo switch.
  bool rejectUploads = false;

  /// Fails this many times, then accepts. Used to exercise retry.
  int failuresBeforeSuccess = 0;

  final List<String> submissionIds = [];
  final Set<String> acceptedIds = {};

  @override
  Future<void> upload(LocationRecord record) async {
    submissionIds.add(record.id);
    if (rejectUploads) {
      throw LocationApiException('server unavailable');
    }
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess -= 1;
      throw LocationApiException('server unavailable');
    }
    acceptedIds.add(record.id);
  }
}
