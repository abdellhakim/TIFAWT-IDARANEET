import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/connectivity/network_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../data/sync_gateway.dart';
import '../domain/sync_operation.dart';

enum SyncPhase { idle, offline, reconnected, syncing, done, failed }

class SyncState {
  const SyncState({required this.phase, required this.pending, this.lastSyncAt, this.inFlight = 0});

  final SyncPhase phase;
  final int pending;
  final int inFlight;
  final DateTime? lastSyncAt;

  SyncState copyWith({SyncPhase? phase, int? pending, int? inFlight, DateTime? lastSyncAt}) => SyncState(
    phase: phase ?? this.phase,
    pending: pending ?? this.pending,
    inFlight: inFlight ?? this.inFlight,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
  );
}

/// One-shot messages for the UI (snackbars).
enum SyncNotice { savedOffline }

final syncGatewayProvider = Provider<SyncGateway>(
  (ref) => ApiConfig.enabled ? HttpSyncGateway(ApiClient(ApiConfig.baseUrl)) : const SimulatedSyncGateway(),
);

/// Sync Manager: local writes never wait for the network. Each change is
/// queued, and the queue is flushed whenever the device is online:
/// detect → read queue → send → server validates → confirm → delete.
/// Unconfirmed operations stay queued and are retried.
class SyncManager extends Notifier<SyncState> {
  static const _uuid = Uuid();
  static const _retryDelay = Duration(seconds: 15);

  final _notices = StreamController<SyncNotice>.broadcast();
  Stream<SyncNotice> get notices => _notices.stream;

  Timer? _retryTimer;
  Timer? _phaseTimer;
  bool _flushing = false;

  /// Set when operations are queued while a flush is already in flight.
  bool _rerun = false;
  DateTime _lastNotice = DateTime(2000);

  Box get _queue => LocalStore.box(Boxes.syncQueue);
  Box get _settings => LocalStore.box(Boxes.settings);

  @override
  SyncState build() {
    ref.listen<bool>(isOnlineProvider, (previous, online) {
      if (previous == online) return;
      online ? _onReconnected() : _onDisconnected();
    });
    ref.onDispose(() {
      _retryTimer?.cancel();
      _phaseTimer?.cancel();
    });

    final online = ref.read(isOnlineProvider);
    if (online && _queue.isNotEmpty) {
      Future.microtask(() => flush(visible: false));
    }
    final last = _settings.get('lastSyncAt') as String?;
    return SyncState(
      phase: online ? SyncPhase.idle : SyncPhase.offline,
      pending: _queue.length,
      lastSyncAt: last == null ? null : DateTime.tryParse(last),
    );
  }

  List<SyncOperation> pendingOperations() {
    final ops = [for (final raw in _queue.values) SyncOperation.fromJson(raw as Map)]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return ops;
  }

  Future<void> enqueue({
    required String userId,
    required String entity,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final op = SyncOperation(
      id: _uuid.v4(),
      entity: entity,
      operation: operation,
      timestamp: DateTime.now(),
      payload: payload,
      userId: userId,
    );
    await _queue.put(op.id, op.toJson());
    state = state.copyWith(pending: _queue.length);

    if (ref.read(isOnlineProvider)) {
      if (_flushing) _rerun = true;
      unawaited(flush(visible: false));
    } else if (!op.isCredential && DateTime.now().difference(_lastNotice) > const Duration(seconds: 2)) {
      _lastNotice = DateTime.now();
      _notices.add(SyncNotice.savedOffline);
    }
  }

  /// [visible] drives the banner sequence (reconnect, manual sync); routine
  /// background flushes stay silent.
  Future<void> flush({bool visible = true}) async {
    if (_flushing) return;
    if (!ref.read(isOnlineProvider)) {
      state = state.copyWith(phase: SyncPhase.offline);
      return;
    }

    final ops = pendingOperations();
    if (ops.isEmpty) {
      if (visible) _showThenIdle(SyncPhase.done);
      return;
    }

    _flushing = true;
    _retryTimer?.cancel();
    if (visible) {
      _phaseTimer?.cancel();
      state = state.copyWith(phase: SyncPhase.syncing, inFlight: ops.length);
    }

    try {
      final confirmed = await ref.read(syncGatewayProvider).push(ops);
      for (final op in ops) {
        confirmed.contains(op.id)
            ? await _queue.delete(op.id)
            : await _queue.put(op.id, op.retried().toJson());
      }
      final now = DateTime.now();
      await _settings.put('lastSyncAt', now.toIso8601String());
      state = state.copyWith(pending: _queue.length, lastSyncAt: now, inFlight: 0);
      if (visible) _showThenIdle(SyncPhase.done);
      if (_queue.isNotEmpty) _scheduleRetry();
    } catch (_) {
      for (final op in ops) {
        await _queue.put(op.id, op.retried().toJson());
      }
      state = state.copyWith(pending: _queue.length, inFlight: 0);
      if (visible) _showThenIdle(SyncPhase.failed);
      _scheduleRetry();
    } finally {
      _flushing = false;
    }
    if (_rerun && state.phase != SyncPhase.failed) {
      _rerun = false;
      unawaited(flush(visible: false));
    }
  }

  /// Drops queued operations of a deleted account.
  Future<void> discardFor(String userId) async {
    for (final op in pendingOperations().where((o) => o.userId == userId)) {
      await _queue.delete(op.id);
    }
    state = state.copyWith(pending: _queue.length);
  }

  void _onDisconnected() {
    _retryTimer?.cancel();
    _phaseTimer?.cancel();
    state = state.copyWith(phase: SyncPhase.offline);
  }

  void _onReconnected() {
    _phaseTimer?.cancel();
    state = state.copyWith(phase: SyncPhase.reconnected);
    _phaseTimer = Timer(const Duration(milliseconds: 1400), () => flush());
  }

  void _showThenIdle(SyncPhase phase) {
    _phaseTimer?.cancel();
    state = state.copyWith(phase: phase);
    _phaseTimer = Timer(const Duration(seconds: 3), () {
      if (state.phase == phase) {
        state = state.copyWith(phase: ref.read(isOnlineProvider) ? SyncPhase.idle : SyncPhase.offline);
      }
    });
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () => flush(visible: false));
  }
}

final syncProvider = NotifierProvider<SyncManager, SyncState>(SyncManager.new);
