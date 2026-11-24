import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracker/models/location_record.dart';
import 'package:tracker/tracking/tracking_cubit.dart';
import 'package:tracker/tracking/tracking_state.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver tracking')),
      body: BlocBuilder<TrackingCubit, TrackingState>(
        builder: (context, state) {
          final cubit = context.read<TrackingCubit>();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _StatusChip(
                            label: state.isTracking ? 'Tracking' : 'Stopped',
                            color: state.isTracking
                                ? const Color(0xFF146C43)
                                : const Color(0xFF667085),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: state.isOnline ? 'Online' : 'Offline',
                            color: state.isOnline
                                ? const Color(0xFF175CD3)
                                : const Color(0xFFB54708),
                          ),
                          if (state.isSyncing) ...[
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Simulated route around India Gate. Points are written locally first, then uploaded.',
                        style: TextStyle(height: 1.35),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: state.isTracking ? null : cubit.start,
                              child: const Text('Start'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: state.isTracking ? cubit.stop : null,
                              child: const Text('Stop'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Simulate offline'),
                        subtitle: const Text(
                          'Keep capturing, but do not upload',
                        ),
                        value: state.forceOffline,
                        onChanged: cubit.setForceOffline,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fail uploads'),
                        subtitle: const Text(
                          'Mock server rejects the point so retry can run',
                        ),
                        value: state.rejectUploads,
                        onChanged: cubit.setRejectUploads,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.pendingCount} pending · ${state.syncedCount} synced',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (_banner(state) case final message?) ...[
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: TextStyle(
                            color: state.statusMessage == null
                                ? const Color(0xFFB54708)
                                : Theme.of(context).colorScheme.error,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              if (state.records.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No locations yet. Press Start.')),
                )
              else
                SliverList.separated(
                  itemCount: state.records.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 20, endIndent: 20),
                  itemBuilder: (context, index) {
                    return _LocationTile(record: state.records[index]);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  String? _banner(TrackingState state) {
    if (state.statusMessage != null) return state.statusMessage;
    if (!state.isOnline && state.pendingCount > 0) {
      final noun = state.pendingCount == 1 ? 'point' : 'points';
      return '${state.pendingCount} $noun saved on this phone. They upload when the connection is back.';
    }
    return null;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.record});

  final LocationRecord record;

  @override
  Widget build(BuildContext context) {
    final attempt = record.synced || record.attemptCount == 0
        ? ''
        : ' · ${record.attemptCount} failed';
    return ListTile(
      title: Text(
        '${record.latitude.toStringAsFixed(5)}, ${record.longitude.toStringAsFixed(5)}',
      ),
      subtitle: Text('${_clock(record.capturedAt)} · ${record.id}$attempt'),
      trailing: Text(
        record.synced ? 'Synced' : 'Pending',
        style: TextStyle(
          color: record.synced
              ? const Color(0xFF146C43)
              : const Color(0xFFB54708),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _clock(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}
