import 'package:equatable/equatable.dart';
import 'package:tracker/models/location_record.dart';

class TrackingState extends Equatable {
  const TrackingState({
    this.isTracking = false,
    this.isOnline = true,
    this.isSyncing = false,
    this.forceOffline = false,
    this.rejectUploads = false,
    this.records = const [],
    this.statusMessage,
  });

  final bool isTracking;
  final bool isOnline;
  final bool isSyncing;
  final bool forceOffline;
  final bool rejectUploads;
  final List<LocationRecord> records;
  final String? statusMessage;

  int get pendingCount => records.where((record) => !record.synced).length;

  int get syncedCount => records.length - pendingCount;

  TrackingState copyWith({
    bool? isTracking,
    bool? isOnline,
    bool? isSyncing,
    bool? forceOffline,
    bool? rejectUploads,
    List<LocationRecord>? records,
    String? statusMessage,
    bool clearMessage = false,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      forceOffline: forceOffline ?? this.forceOffline,
      rejectUploads: rejectUploads ?? this.rejectUploads,
      records: records ?? this.records,
      statusMessage: clearMessage
          ? null
          : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
    isTracking,
    isOnline,
    isSyncing,
    forceOffline,
    rejectUploads,
    records,
    statusMessage,
  ];
}
