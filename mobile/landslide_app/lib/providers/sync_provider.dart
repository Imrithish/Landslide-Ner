import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_sync_service.dart';
import 'auth_provider.dart';

final offlineSyncProvider = Provider<OfflineSyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localCache = ref.watch(localCacheProvider);
  return OfflineSyncService(apiClient: apiClient, localCache: localCache);
});

class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final int? lastSyncedCount;
  final String? errorMessage;

  SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncedCount,
    this.errorMessage,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? lastSyncedCount,
    String? errorMessage,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedCount: lastSyncedCount ?? this.lastSyncedCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final OfflineSyncService _syncService;

  SyncNotifier(this._syncService) : super(SyncState(
    pendingCount: _syncService.pendingReportsCount,
  ));

  Future<void> syncNow() async {
    state = state.copyWith(isSyncing: true);
    try {
      final count = await _syncService.syncPendingReports();
      state = state.copyWith(
        isSyncing: false,
        lastSyncedCount: count,
        pendingCount: _syncService.pendingReportsCount,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
        pendingCount: _syncService.pendingReportsCount,
      );
    }
  }

  void refreshPendingCount() {
    state = state.copyWith(pendingCount: _syncService.pendingReportsCount);
  }
}

final syncStateProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(offlineSyncProvider);
  return SyncNotifier(syncService);
});
