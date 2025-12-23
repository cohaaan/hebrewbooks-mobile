import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hebrewbooks/l10n/app_localizations.dart';
import 'package:hebrewbooks/providers/settings_provider.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:provider/provider.dart';

/// Settings screen for app configuration
class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          l10n?.settings ?? 'Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Language Section
              _buildSectionTitle(context, l10n?.language ?? 'Language'),
              const SizedBox(height: 8),
              _buildLanguageSelector(context, settingsProvider, l10n),
              const SizedBox(height: 24),

              // Theme Section
              _buildSectionTitle(context, l10n?.theme ?? 'Theme'),
              const SizedBox(height: 8),
              _buildThemeSelector(context, settingsProvider, l10n),
              const SizedBox(height: 24),

              // Network Usage Section
              _buildSectionTitle(context, l10n?.networkUsage ?? 'Network Usage'),
              const SizedBox(height: 8),
              _buildNetworkUsageSwitch(context, settingsProvider, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return CustomText(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    SettingsProvider settingsProvider,
    AppLocalizations? l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(
              value: 'en',
              label: CustomText(l10n?.english ?? 'English'),
              icon: const Icon(Icons.language),
            ),
            ButtonSegment<String>(
              value: 'he',
              label: CustomText(l10n?.hebrew ?? 'Hebrew'),
              icon: const Icon(Icons.language),
            ),
          ],
          selected: {settingsProvider.language},
          onSelectionChanged: (Set<String> newSelection) {
            final newLanguage = newSelection.first;
            settingsProvider.setLanguage(newLanguage);
            FirebaseAnalytics.instance.logEvent(
              name: 'settings_language_changed',
              parameters: {'language': newLanguage},
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    SettingsProvider settingsProvider,
    AppLocalizations? l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              label: CustomText(l10n?.light ?? 'Light'),
              icon: const Icon(Icons.light_mode),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              label: CustomText(l10n?.dark ?? 'Dark'),
              icon: const Icon(Icons.dark_mode),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              label: CustomText(l10n?.system ?? 'System'),
              icon: const Icon(Icons.settings_suggest),
            ),
          ],
          selected: {settingsProvider.themeMode},
          onSelectionChanged: (Set<ThemeMode> newSelection) {
            final newThemeMode = newSelection.first;
            settingsProvider.setThemeMode(newThemeMode);
            FirebaseAnalytics.instance.logEvent(
              name: 'settings_theme_changed',
              parameters: {'theme': newThemeMode.toString()},
            );
          },
        ),
      ),
    );
  }

  Widget _buildNetworkUsageSwitch(
    BuildContext context,
    SettingsProvider settingsProvider,
    AppLocalizations? l10n,
  ) {
    return Card(
      child: SwitchListTile(
        title: CustomText(l10n?.allowMobileData ?? 'Allow mobile data usage'),
        subtitle: CustomText(
          settingsProvider.allowMobileData
              ? 'Downloads allowed on mobile data'
              : 'Downloads restricted to WiFi only',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: settingsProvider.allowMobileData,
        onChanged: (bool value) {
          settingsProvider.setAllowMobileData(value);
          FirebaseAnalytics.instance.logEvent(
            name: 'settings_mobile_data_changed',
            parameters: {'allow_mobile_data': value},
          );
        },
      ),
    );
  }
}
