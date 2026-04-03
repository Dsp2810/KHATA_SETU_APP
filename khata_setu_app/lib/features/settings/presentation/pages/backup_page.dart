import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/drive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/animations.dart';
import '../bloc/backup_cubit.dart';
import '../bloc/backup_state.dart';

/// Backup & Safety page — connect Google Drive, backup, restore.
class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BackupCubit>()..init(),
      child: const _BackupPageView(),
    );
  }
}

class _BackupPageView extends StatelessWidget {
  const _BackupPageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm, AppSpacing.sm, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back_rounded,
                            color: context.textPrimaryColor),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Backup & Safety',
                          style: AppTextStyles.h3.copyWith(
                              color: context.textPrimaryColor)),
                    ],
                  ),
                ),
              ),

              // ─── Body ───
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: BlocConsumer<BackupCubit, BackupState>(
                    listener: _onStateChange,
                    builder: (context, state) {
                      return Column(
                        children: [
                          // ─── Drive illustration ───
                          AnimatedListItem(
                            index: 0,
                            child: _buildHeader(context),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // ─── Connection Card ───
                          AnimatedListItem(
                            index: 1,
                            child: _buildConnectionCard(context, state),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // ─── Backup & Restore Actions ───
                          AnimatedListItem(
                            index: 2,
                            child: _buildActionCard(context, state),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // ─── Restore selection (if visible) ───
                          if (state is BackupRestorePointsLoaded)
                            AnimatedListItem(
                              index: 3,
                              child: _buildRestoreList(
                                  context, state.backups),
                            ),

                          // ─── Restore complete ───
                          if (state is BackupRestoreComplete)
                            AnimatedListItem(
                              index: 3,
                              child:
                                  _buildRestoreResult(context, state),
                            ),

                          const SizedBox(height: AppSpacing.navClearance),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Listener ──────────────────────────────────────────────

  void _onStateChange(BuildContext context, BackupState state) {
    if (state is BackupIdle && state.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message!),
          backgroundColor:
              state.isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Header ────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.cloud_done_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Keep Your Data Safe',
              style: AppTextStyles.h4.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Connect Google Drive to automatically save your shop data. '
            'Restore anytime on any device.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  // ─── Connection Card ──────────────────────────────────────

  Widget _buildConnectionCard(BuildContext context, BackupState state) {
    final isConnecting = state is BackupConnecting;

    // Determine connection info
    bool connected = false;
    String? email;
    if (state is BackupIdle) {
      connected = state.isConnected;
      email = state.connectedEmail;
    } else if (state is BackupInProgress ||
        state is BackupRestorePointsLoaded ||
        state is BackupRestoreInProgress ||
        state is BackupRestoreComplete ||
        state is BackupListingRestorePoints) {
      connected = true;
    }

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (connected ? AppColors.success : AppColors.grey400)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  connected
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: connected ? AppColors.success : AppColors.grey400,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Google Drive',
                        style: AppTextStyles.labelLarge.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w600)),
                    Text(
                      connected
                          ? (email ?? 'Connected')
                          : 'Not connected',
                      style: AppTextStyles.caption
                          .copyWith(color: context.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              if (connected)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Connected',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Connect / Disconnect Button ───
          SizedBox(
            width: double.infinity,
            child: connected
                ? OutlinedButton.icon(
                    onPressed: isConnecting
                        ? null
                        : () => context.read<BackupCubit>().disconnectDrive(),
                    icon: const Icon(Icons.link_off_rounded, size: 18),
                    label: const Text('Disconnect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: isConnecting
                        ? null
                        : () => context.read<BackupCubit>().connectDrive(),
                    icon: isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add_link_rounded, size: 18),
                    label: Text(isConnecting
                        ? 'Connecting…'
                        : 'Connect Google Drive'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Action Card ──────────────────────────────────────────

  Widget _buildActionCard(BuildContext context, BackupState state) {
    final isIdle = state is BackupIdle;
    final connected = isIdle && state.isConnected;
    final isWorking = state is BackupInProgress ||
        state is BackupRestoreInProgress ||
        state is BackupListingRestorePoints;

    // Last backup info
    DateTime? lastBackup;
    if (isIdle) lastBackup = state.lastBackupTime;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.backup_rounded,
                    color: AppColors.info, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Backup & Restore',
                  style: AppTextStyles.labelLarge.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ─── Last Backup Info ───
          if (lastBackup != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Last backup: ${AppFormatter.relativeTime(lastBackup, context.l10n)}',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Progress Indicator ───
          if (state is BackupInProgress) _buildProgress(context, state.stage),
          if (state is BackupRestoreInProgress)
            _buildProgress(context, state.stage),
          if (state is BackupListingRestorePoints)
            _buildProgress(context, 'loading backups'),

          // ─── Backup Button ───
          _buildActionTile(
            icon: Icons.cloud_upload_rounded,
            title: 'Backup Now',
            subtitle: 'Save your data to Google Drive',
            enabled: connected && !isWorking,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.read<BackupCubit>().startBackup();
            },
          ),
          const Divider(height: 1),

          // ─── Restore Button ───
          _buildActionTile(
            icon: Icons.cloud_download_rounded,
            title: 'Restore Backup',
            subtitle: 'Download & restore from Google Drive',
            enabled: connected && !isWorking,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.read<BackupCubit>().listRestorePoints();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, String stage) {
    final stageLabel = switch (stage) {
      'exporting' => 'Exporting data…',
      'encrypting' => 'Encrypting…',
      'uploading' => 'Uploading to Drive…',
      'downloading' => 'Downloading backup…',
      'decrypting' => 'Decrypting…',
      'importing' => 'Restoring data…',
      _ => stage,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          const LinearProgressIndicator(
            minHeight: 3,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(stageLabel,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color: enabled
                    ? AppColors.primary
                    : AppColors.grey400),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: enabled
                              ? null
                              : AppColors.grey400)),
                  Text(subtitle,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey400)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color: enabled
                    ? AppColors.grey400
                    : AppColors.grey300),
          ],
        ),
      ),
    );
  }

  // ─── Restore List ─────────────────────────────────────────

  Widget _buildRestoreList(
      BuildContext context, List<DriveBackupMeta> backups) {
    if (backups.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: context.textTertiaryColor),
            const SizedBox(height: AppSpacing.sm),
            Text('No Backups Found',
                style: AppTextStyles.labelLarge.copyWith(
                    color: context.textPrimaryColor)),
            const SizedBox(height: AppSpacing.xxs),
            Text('Create your first backup using "Backup Now"',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption
                    .copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () =>
                  context.read<BackupCubit>().cancelRestore(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restore_rounded,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Select Backup to Restore',
                    style: AppTextStyles.labelLarge.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w600)),
              ),
              IconButton(
                onPressed: () =>
                    context.read<BackupCubit>().cancelRestore(),
                icon: Icon(Icons.close_rounded,
                    size: 20, color: context.textSecondaryColor),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ─── Warning ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Restoring will replace ALL current data. '
                    'Consider backing up first.',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ─── Backup Items ───
          ...backups.map((b) => _buildRestoreItem(context, b)),
        ],
      ),
    );
  }

  Widget _buildRestoreItem(
      BuildContext context, DriveBackupMeta backup) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final sizeKb = (backup.sizeBytes / 1024).toStringAsFixed(1);

    return InkWell(
      onTap: () => _confirmRestore(context, backup),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateFormat.format(backup.createdAt),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.textPrimaryColor)),
                  Text('$sizeKb KB',
                      style: AppTextStyles.caption
                          .copyWith(color: context.textSecondaryColor)),
                ],
              ),
            ),
            Icon(Icons.download_rounded,
                size: 20, color: context.textSecondaryColor),
          ],
        ),
      ),
    );
  }

  void _confirmRestore(BuildContext context, DriveBackupMeta backup) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Restore Backup?'),
        content: Text(
          'This will replace ALL current data with the backup from '
          '${dateFormat.format(backup.createdAt)}.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<BackupCubit>()
                  .restoreFromBackup(backup.fileId);
            },
            child: const Text('Restore',
                style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  // ─── Restore Result ───────────────────────────────────────

  Widget _buildRestoreResult(
      BuildContext context, BackupRestoreComplete state) {
    final result = state.result;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: AppGradients.successGradient,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Restore Complete!',
              style: AppTextStyles.h4.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text('Backup from ${dateFormat.format(result.snapshotDate)}',
              style: AppTextStyles.caption
                  .copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: AppSpacing.md),

          // ─── Stats ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                ...result.counts.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_capitalize(e.key),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: context.textSecondaryColor)),
                        Text('${e.value}',
                            style: AppTextStyles.labelMedium.copyWith(
                                color: context.textPrimaryColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Records',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w600)),
                    Text('${result.totalRecords}',
                        style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  context.read<BackupCubit>().acknowledgeRestore(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
