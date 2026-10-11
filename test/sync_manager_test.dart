import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tifawt/core/connectivity/network_manager.dart';
import 'package:tifawt/core/storage/local_store.dart';
import 'package:tifawt/features/synchronization/application/sync_manager.dart';
import 'package:tifawt/features/synchronization/data/sync_gateway.dart';
import 'package:tifawt/features/synchronization/domain/sync_operation.dart';

class RecordingGateway implements SyncGateway {
  final received = <SyncOperation>[];
  bool fail = false;
  Duration delay = Duration.zero;

  @override
  bool get isSimulated => true;

  @override
  Future<Set<String>> push(List<SyncOperation> operations) async {
    await Future<void>.delayed(delay);
    if (fail) throw Exception('server down');
    received.addAll(operations);
    return {for (final op in operations) op.id};
  }
}

final online = StateProvider<bool>((ref) => false);

void main() {
  late Directory dir;
  late RecordingGateway gateway;
  late ProviderContainer container;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('tifawt_sync_');
    Hive.init(dir.path);
    await Hive.openBox(Boxes.settings);
    await Hive.openBox(Boxes.syncQueue);
    gateway = RecordingGateway();
    container = ProviderContainer(
      overrides: [
        syncGatewayProvider.overrideWithValue(gateway),
        isOnlineProvider.overrideWith((ref) => ref.watch(online)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> enqueueStatusChange() => container
      .read(syncProvider.notifier)
      .enqueue(
        userId: 'demo-chahd',
        entity: SyncEntity.application,
        operation: SyncOp.update,
        payload: {'opportunityId': 'op_numerique_init', 'status': 'registered'},
      );

  test('offline action is stored locally and announced', () async {
    final notices = <SyncNotice>[];
    container.read(syncProvider.notifier).notices.listen(notices.add);

    await enqueueStatusChange();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(syncProvider).pending, 1);
    expect(notices, [SyncNotice.savedOffline]);
    expect(gateway.received, isEmpty);

    final stored = SyncOperation.fromJson(Hive.box(Boxes.syncQueue).values.single as Map);
    expect(stored.toWire().keys, containsAll(['entity', 'operation', 'timestamp', 'payload']));
  });

  test('reconnection: rétablie → en cours → terminée, queue emptied', () async {
    final phases = <SyncPhase>[];
    container.listen(syncProvider.select((s) => s.phase), (_, p) => phases.add(p), fireImmediately: true);

    await enqueueStatusChange();
    container.read(online.notifier).state = true;
    await Future<void>.delayed(const Duration(milliseconds: 1700));

    expect(phases, containsAllInOrder([SyncPhase.reconnected, SyncPhase.syncing, SyncPhase.done]));
    expect(gateway.received.single.payload['status'], 'registered');
    expect(container.read(syncProvider).pending, 0);
    expect(container.read(syncProvider).lastSyncAt, isNotNull);
  });

  test('operations queued during a flush are sent right after it, not at the next retry', () async {
    container.read(online.notifier).state = true;
    gateway.delay = const Duration(milliseconds: 300);
    await enqueueStatusChange(); // starts a flush
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await container
        .read(syncProvider.notifier)
        .enqueue(
          userId: 'demo-chahd',
          entity: SyncEntity.badge,
          operation: SyncOp.create,
          payload: {'code': 'FIRST_OPPORTUNITY'},
        );
    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(gateway.received.map((o) => o.entity), [SyncEntity.application, SyncEntity.badge]);
    expect(container.read(syncProvider).pending, 0);
  });

  test('failed push keeps the operation for a retry', () async {
    gateway.fail = true;
    await enqueueStatusChange();
    container.read(online.notifier).state = true;
    await Future<void>.delayed(const Duration(milliseconds: 1700));

    expect(container.read(syncProvider).phase, SyncPhase.failed);
    final op = container.read(syncProvider.notifier).pendingOperations().single;
    expect(op.attempts, 1);
  });
}
