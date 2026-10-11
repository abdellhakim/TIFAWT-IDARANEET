import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_store.dart';

class NetworkState {
  const NetworkState({required this.deviceOnline, required this.simulatedOffline});

  final bool deviceOnline;

  /// Demo switch: behaves as if the network were cut.
  final bool simulatedOffline;

  bool get isOnline => deviceOnline && !simulatedOffline;

  NetworkState copyWith({bool? deviceOnline, bool? simulatedOffline}) => NetworkState(
    deviceOnline: deviceOnline ?? this.deviceOnline,
    simulatedOffline: simulatedOffline ?? this.simulatedOffline,
  );
}

/// Detects connectivity. The app never waits on it — it only decides when
/// the sync queue can be flushed and when to show the offline banner.
class NetworkManager extends Notifier<NetworkState> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  NetworkState build() {
    final connectivity = Connectivity();
    _sub = connectivity.onConnectivityChanged.listen(_onResults);
    connectivity.checkConnectivity().then(_onResults).catchError((_) {});
    ref.onDispose(() => _sub?.cancel());

    final simulated = LocalStore.box(Boxes.settings).get('simulateOffline') as bool? ?? false;
    return NetworkState(deviceOnline: true, simulatedOffline: simulated);
  }

  void _onResults(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != state.deviceOnline) state = state.copyWith(deviceOnline: online);
  }

  Future<void> setSimulatedOffline(bool value) async {
    state = state.copyWith(simulatedOffline: value);
    await LocalStore.box(Boxes.settings).put('simulateOffline', value);
  }
}

final networkProvider = NotifierProvider<NetworkManager, NetworkState>(NetworkManager.new);

final isOnlineProvider = Provider<bool>((ref) => ref.watch(networkProvider).isOnline);
