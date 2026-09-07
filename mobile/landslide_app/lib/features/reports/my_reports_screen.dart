import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/report_provider.dart';
import '../../providers/sync_provider.dart';
import '../../constants/app_colors.dart';
import '../../models/report.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import 'report_hazard_screen.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(userReportsProvider);
    final syncState = ref.watch(syncStateProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        actions: [
          if (syncState.pendingCount > 0)
            IconButton(
              icon: Icon(Icons.sync_rounded,
                  color: syncState.isSyncing ? AppColors.primary : AppColors.warning),
              onPressed: syncState.isSyncing
                  ? null
                  : () => ref.read(syncStateProvider.notifier).syncNow(),
              tooltip: 'Sync ' + syncState.pendingCount.toString() + ' offline report(s)',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(userReportsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onTap: () => Navigator.of(context).push(
         98
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report Hazard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (syncState.pendingCount > 0 && !syncState.isSyncing)
           78
            ],
          ),
        ),
      ),
    );
  }
}
