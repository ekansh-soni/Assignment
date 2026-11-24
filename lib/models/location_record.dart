import 'package:equatable/equatable.dart';

/// A captured point that lives on the phone until the server accepts it.
///
/// [id] is created once, when the point is stored, and sent again on every
/// retry. The server uses it to ignore a duplicate delivery.
class LocationRecord extends Equatable {
  const LocationRecord({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    required this.attemptCount,
    required this.synced,
  });

  final String id;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final int attemptCount;
  final bool synced;

  factory LocationRecord.fromMap(Map<String, Object?> map) {
    return LocationRecord(
      id: map['id']! as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      capturedAt: DateTime.parse(map['captured_at']! as String),
      attemptCount: map['attempt_count']! as int,
      synced: (map['synced']! as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'attempt_count': attemptCount,
      'synced': synced ? 1 : 0,
    };
  }

  @override
  List<Object?> get props => [
    id,
    latitude,
    longitude,
    capturedAt,
    attemptCount,
    synced,
  ];
}
