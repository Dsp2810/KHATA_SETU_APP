import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/data/hive_initializer.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../bloc/theme_cubit.dart';
import '../bloc/language_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final LocalStorageService _localStorage;
  late bool _notificationsEnabled;
  String _userName = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _localStorage = getIt<LocalStorageService>();
    _notificationsEnabled = _localStorage.getBool('notifications_enabled') ?? true;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final secureStorage = getIt<SecureStorageService>();
    final name = await secureStorage.read('user_name') ?? '';
    final phone = await secureStorage.read('user_phone') ?? '';
    if (mounted) {
      setState(() {
        _userName = name;
        _userPhone = phone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final themeCubit = context.watch<ThemeCubit>();
    final currentTheme = themeCubit.state;

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
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                  child: Text(context.l10n.settings,
                      style: AppTextStyles.h2
                          .copyWith(color: context.textPrimaryColor)),
                ),
              ),

              // ─── Profile Card ───
              SliverToBoxAdapter(
                child: AnimatedListItem(
                  index: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              gradient: AppGradients.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('R',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_userName.isNotEmpty ? _userName : 'User',
                                    style: AppTextStyles.h4.copyWith(
                                        color: context.textPrimaryColor,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(_userPhone.isNotEmpty ? _userPhone : '',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: context.textSecondaryColor)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: context.textSecondaryColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Settings Sections ───
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.navClearance),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Appearance ──
                    AnimatedListItem(
                      index: 1,
                      child: _buildSection(context.l10n.appearance, Icons.palette_outlined,
                          AppColors.primary, [
                        _buildThemeTile(currentTheme, themeCubit, isDark),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Language ──
                    AnimatedListItem(
                      index: 2,
                      child: _buildSection(context.l10n.language, Icons.translate_rounded,
                          AppColors.info, [
                        _buildLanguageTile(isDark),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Payments ──
                    AnimatedListItem(
                      index: 3,
                      child: _buildSection(
                          context.l10n.payments, Icons.payment_rounded, AppColors.teal, [
                        _buildSettingsTile(
                          icon: Icons.qr_code_rounded,
                          title: context.l10n.upiQrSetup,
                          subtitle: context.l10n.upiQrSetupSubtitle,
                          onTap: () =>
                              context.push(RouteConstants.upiSetup),
                        ),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Notifications ──
                    AnimatedListItem(
                      index: 4,
                      child: _buildSection(context.l10n.notifications,
                          Icons.notifications_outlined, AppColors.warning, [
                        _buildSwitchTile(
                          icon: Icons.notifications_active_rounded,
                          title: context.l10n.pushNotifications,
                          subtitle: context.l10n.pushNotificationsSubtitle,
                          value: _notificationsEnabled,
                          onChanged: (v) {
                            setState(() => _notificationsEnabled = v);
                            _localStorage.setBool('notifications_enabled', v);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.notificationsComingSoon),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Security ──
                    AnimatedListItem(
                      index: 5,
                      child: _buildSection(
                          context.l10n.security, Icons.shield_outlined, AppColors.success, [
                        _buildSettingsTile(
                          icon: Icons.lock_outline_rounded,
                          title: context.l10n.changePin,
                          subtitle: context.l10n.changePinSubtitle,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(context.l10n.comingSoon),
                                  behavior: SnackBarBehavior.floating),
                            );
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Data & Sync ──
                    AnimatedListItem(
                      index: 6,
                      child: _buildSection(context.l10n.dataAndSync,
                          Icons.sync_rounded, AppColors.secondary, [
                        _buildSettingsTile(
                          icon: Icons.cloud_upload_outlined,
                          title: context.l10n.syncNow,
                          subtitle: _localStorage.getLastSyncTime() != null
                              ? context.l10n.lastSynced(AppFormatter.relativeTime(_localStorage.getLastSyncTime()!, context.l10n))
                              : context.l10n.syncNowSubtitle,
                          onTap: () async {
                            final isOnline = getIt<ConnectivityService>().isOnline;
                            if (!isOnline) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.syncRequiresBackend),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            if (!getIt.isRegistered<SyncService>()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.syncRequiresBackend),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.syncStarted),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            try {
                              await getIt<SyncService>().syncAll();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.l10n.syncComplete),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                setState(() {});
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.l10n.syncFailed),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.backup_outlined,
                          title: context.l10n.exportBackup,
                          subtitle: context.l10n.exportBackupSubtitle,
                          onTap: () => _exportData(),
                        ),
                        _buildSettingsTile(
                          icon: Icons.cloud_done_outlined,
                          title: 'Google Drive Backup',
                          subtitle: 'Encrypt & backup to Google Drive',
                          onTap: () => context.push(RouteConstants.backup),
                        ),
                        _buildDangerTile(
                          icon: Icons.delete_forever_rounded,
                          title: context.l10n.clearAllData,
                          subtitle: context.l10n.clearAllDataSubtitle,
                          onTap: () => _confirmClearData(),
                        ),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── About ──
                    AnimatedListItem(
                      index: 7,
                      child: _buildSection(
                          context.l10n.about, Icons.info_outline_rounded, AppColors.grey500, [
                        _buildSettingsTile(
                          icon: Icons.description_outlined,
                          title: context.l10n.termsAndConditions,
                          subtitle: context.l10n.termsSubtitle,
                          onTap: () async {
                            final uri = Uri.parse('https://khatasetu.com/terms');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: context.l10n.privacyPolicy,
                          subtitle: context.l10n.privacySubtitle,
                          onTap: () async {
                            final uri = Uri.parse('https://khatasetu.com/privacy');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.star_outline_rounded,
                          title: context.l10n.rateApp,
                          subtitle: context.l10n.rateAppSubtitle,
                          onTap: () async {
                            final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.khataSetu.khata_setu');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Center(
                            child: Text(
                              '${AppConstants.appName} v${AppConstants.appVersion}',
                              style: AppTextStyles.caption
                                  .copyWith(color: context.textTertiaryColor),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Builder ───
  Widget _buildSection(
      String title, IconData icon, Color color, List<Widget> children) {
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(title,
                  style: AppTextStyles.labelLarge.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  // ─── Theme Tile ───
  Widget _buildThemeTile(
      ThemeMode current, ThemeCubit cubit, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            _buildThemeOption(
              label: context.l10n.lightTheme,
              icon: Icons.light_mode_rounded,
              isSelected: current == ThemeMode.light,
              onTap: () {
                cubit.setTheme(ThemeMode.light);
                HapticFeedback.selectionClick();
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildThemeOption(
              label: context.l10n.darkTheme,
              icon: Icons.dark_mode_rounded,
              isSelected: current == ThemeMode.dark,
              onTap: () {
                cubit.setTheme(ThemeMode.dark);
                HapticFeedback.selectionClick();
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildThemeOption(
              label: context.l10n.systemTheme,
              icon: Icons.settings_brightness_rounded,
              isSelected: current == ThemeMode.system,
              onTap: () {
                cubit.setSystemTheme();
                HapticFeedback.selectionClick();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.primaryGradient : null,
            color: isSelected ? null : context.glassColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : context.glassBorderColor),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color:
                      isSelected ? Colors.white : context.textSecondaryColor),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? Colors.white
                        : context.textSecondaryColor,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Language Tile ───
  Widget _buildLanguageTile(bool isDark) {
    final l10n = context.l10n;
    final languageCubit = context.watch<LanguageCubit>();
    final currentCode = languageCubit.languageCode;
    final languages = {
      'en': l10n.languageEnglish,
      'gu': l10n.languageGujarati,
      'hi': l10n.languageHindi,
    };

    return Column(
      children: languages.entries.map((entry) {
        final isSelected = currentCode == entry.key;
        return GestureDetector(
          onTap: () {
            languageCubit.setLocale(entry.key);
            HapticFeedback.selectionClick();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.transparent),
            ),
            child: Row(
              children: [
                Text(entry.value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : context.textPrimaryColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    )),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Generic Tiles ───
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.textSecondaryColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.textPrimaryColor)),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: context.textSecondaryColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: context.textTertiaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.textSecondaryColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: context.textPrimaryColor)),
                Text(subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: context.textSecondaryColor)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.error)),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: context.textSecondaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───
  Future<void> _exportData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.exportingData),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final customerBox = Hive.box<dynamic>('customers');
      final transactionBox = Hive.box<dynamic>('transactions');
      final productBox = Hive.box<dynamic>('products');

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': AppConstants.appVersion,
        'customers': customerBox.values.map((c) => {
          'id': c.id,
          'name': c.name,
          'phone': c.phone,
          'email': c.email,
          'address': c.address,
          'creditLimit': c.creditLimit,
          'currentBalance': c.currentBalance,
          'trustScore': c.trustScore,
          'notes': c.notes,
          'createdAt': c.createdAt.toIso8601String(),
        }).toList(),
        'transactions': transactionBox.values.map((t) => {
          'id': t.id,
          'customerId': t.customerId,
          'type': t.type,
          'amount': t.totalAmount,
          'description': t.description,
          'createdAt': t.timestamp.toIso8601String(),
        }).toList(),
        'products': productBox.values.map((p) => {
          'id': p.id,
          'name': p.name,
          'category': p.category,
          'purchasePrice': p.purchasePrice,
          'sellingPrice': p.sellingPrice,
          'currentStock': p.currentStock,
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/khatasetu_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'KhataSetu Backup',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.exportSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.exportFailed),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmClearData() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.clearAllDataTitle),
        content: Text(l10n.clearAllDataMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await HiveInitializer.clearAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.allDataCleared),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: Text(l10n.clear, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
