import '../../../core/network/api_client.dart';
import '../domain/sync_operation.dart';

/// Where the queue is flushed. Returns the ids the server confirmed;
/// anything not returned stays in the queue for the next attempt.
abstract interface class SyncGateway {
  bool get isSimulated;
  Future<Set<String>> push(List<SyncOperation> operations);
}

/// Used when no API URL is configured (standalone demo): behaves like a
/// server that accepts every operation after a realistic delay.
class SimulatedSyncGateway implements SyncGateway {
  const SimulatedSyncGateway();

  @override
  bool get isSimulated => true;

  @override
  Future<Set<String>> push(List<SyncOperation> operations) async {
    await Future<void>.delayed(Duration(milliseconds: 700 + 180 * operations.length.clamp(0, 10)));
    return {for (final op in operations) op.id};
  }
}

/// Flask REST API.
class HttpSyncGateway implements SyncGateway {
  HttpSyncGateway(this._api);
  final ApiClient _api;

  @override
  bool get isSimulated => false;

  @override
  Future<Set<String>> push(List<SyncOperation> operations) async {
    final confirmed = <String>{};

    // Accounts created or opened offline must exist server-side first.
    for (final op in operations.where((o) => o.isCredential)) {
      final path = op.operation == SyncOp.register ? '/api/auth/register' : '/api/auth/login';
      try {
        final session = await _api.post(path, op.payload, auth: false);
        await _api.storeSession(session);
        confirmed.add(op.id);
      } on ApiException catch (e) {
        // 409 = already registered: credentials are known server-side.
        if (e.status == 409) confirmed.add(op.id);
        if (e.status >= 500) rethrow;
      }
    }

    final data = operations.where((o) => !o.isCredential).toList();
    if (data.isEmpty) return confirmed;

    final response = await _api.post('/api/sync', {
      'operations': [for (final op in data) op.toWire()],
    });
    for (final result in (response['results'] as List).cast<Map>()) {
      if (result['status'] == 'ok' || result['status'] == 'duplicate') {
        confirmed.add(result['id'] as String);
      }
    }
    return confirmed;
  }
}
