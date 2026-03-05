import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/sync_cubit.dart';

/// A compact banner that shows sync status at the top of the main scaffold.
///
/// States:
/// - **Offline**: "No internet — changes saved locally"
/// - **Syncing**: "Syncing X changes…"  (with spinner)
/// - **Failed**:  "Sync failed · Tap to retry"
/// - **Online + 0 pending**: hidden
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      buildWhen: (prev, curr) =>
          prev.showBanner != curr.showBanner ||
          prev.isOnline != curr.isOnline ||
          prev.isSyncing != curr.isSyncing ||
          prev.pendingCount != curr.pendingCount ||
          prev.failedCount != curr.failedCount,
      builder: (context, state) {
        if (!state.showBanner) return const SizedBox.shrink();

        final (icon, label, color, onTap) = _resolve(context, state);

        return Material(
          color: color,
          child: InkWell(
            onTap: onTap,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (state.isSyncing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (state.failedCount > 0)
                      const Icon(Icons.refresh, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  (IconData, String, Color, VoidCallback?) _resolve(
    BuildContext context,
    SyncState state,
  ) {
    if (!state.isOnline) {
      return (
        Icons.cloud_off_rounded,
        'No internet — changes saved locally',
        AppColors.warning,
        null,
      );
    }

    if (state.failedCount > 0 && !state.isSyncing) {
      return (
        Icons.error_outline_rounded,
        'Sync failed (${state.failedCount}) · Tap to retry',
        AppColors.error,
        () => context.read<SyncCubit>().retryFailed(),
      );
    }

    if (state.isSyncing || state.pendingCount > 0) {
      return (
        Icons.sync_rounded,
        'Syncing ${state.pendingCount} change${state.pendingCount == 1 ? '' : 's'}…',
        AppColors.info,
        null,
      );
    }

    // Shouldn't reach here if showBanner is correct, but just in case
    return (Icons.check_circle_outline, 'All synced', AppColors.success, null);
  }
}
