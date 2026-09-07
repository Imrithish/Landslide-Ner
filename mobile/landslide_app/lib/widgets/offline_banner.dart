import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final bool isSyncing;
  final int pendingCount;
  final VoidCallback? onSync;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && pendingCount == 0) return const SizedBox.shrink();

    if (isSyncing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.primary.withAlpha(200),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 8),
            Text('Syncing pending reports...', style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      );
    }

    if (isOffline) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.riskHigh.withAlpha(200),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              pendingCount > 0
                  ? 'Offline — $pendingCount report(s) pending sync'
                  : 'Offline — Viewing cached data',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (pendingCount > 0) {
      return GestureDetector(
        onTap: onSync,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.syncPending.withAlpha(200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                '$pendingCount offline report(s) ready to sync — Tap to sync',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
