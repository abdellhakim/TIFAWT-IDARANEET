import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/network_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_store.dart';
import '../../../shared/models/app_user.dart';
import '../../synchronization/application/sync_manager.dart';
import '../../synchronization/domain/sync_operation.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthController extends Notifier<AppUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AppUser? build() => _repo.currentUser();

  Future<AppUser> login(String identifier, String password) async {
    final user = await _repo.login(identifier, password);
    state = user;
    unawaited(
      _mirror(SyncOp.login, user, {'identifier': Identifier.normalize(identifier), 'password': password}),
    );
    return user;
  }

  Future<AppUser> register({
    required String name,
    required String identifier,
    required String password,
  }) async {
    final user = await _repo.register(name: name, identifier: identifier, password: password);
    state = user;
    unawaited(
      _mirror(SyncOp.register, user, {
        'id': user.id,
        'name': user.name,
        'identifier': Identifier.normalize(identifier),
        'password': password,
      }),
    );
    return user;
  }

  /// Obtains a JWT from the API. Offline, the credential operation waits in
  /// the (encrypted) sync queue and is replayed first on reconnection.
  Future<void> _mirror(String operation, AppUser user, Map<String, dynamic> payload) async {
    if (!ApiConfig.enabled) return;
    final entity = operation == SyncOp.register ? SyncEntity.user : SyncEntity.session;
    if (ref.read(isOnlineProvider)) {
      try {
        final api = ApiClient(ApiConfig.baseUrl);
        final path = operation == SyncOp.register ? '/api/auth/register' : '/api/auth/login';
        await api.storeSession(await api.post(path, payload, auth: false));
        return;
      } catch (_) {
        // Fall through to the queue.
      }
    }
    await ref
        .read(syncProvider.notifier)
        .enqueue(userId: user.id, entity: entity, operation: operation, payload: payload);
  }

  bool get isDemoUser => state != null && _repo.isDemo(state!.id);

  Future<void> logout() async {
    await _repo.logout();
    await SecureStore.instance.clearTokens();
    state = null;
  }

  Future<void> deleteAccount() async {
    final user = state;
    if (user == null) return;
    await ref.read(syncProvider.notifier).discardFor(user.id);
    await _repo.deleteAccount(user.id);
    await SecureStore.instance.clearTokens();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthController, AppUser?>(AuthController.new);
