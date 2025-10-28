import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../layout/adaptive.dart';
import '../theme/app_theme.dart';

void showAboutDialog() {
  Get.dialog(
    const AboutDialogSheet(),
    name: 'About QH',
    barrierDismissible: false,
    transitionCurve: Curves.easeInOutCirc,
  );
}

class AboutDialogSheet extends StatelessWidget {
  const AboutDialogSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      elevation: 0,
      backgroundColor: theme.canvasColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: const AboutView(),
      ),
    );
  }
}

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  AboutViewState createState() => AboutViewState();
}

class AboutViewState extends State<AboutView> with TickerProviderStateMixin {
  final List<Tab> tabs = const <Tab>[
    Tab(text: 'App'),
    Tab(text: 'Author'),
    Tab(text: 'License'),
  ];
  late TabController _tabController;
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: tabs.length);
    _loadInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _info = info);
    } catch (e) {
      debugPrint('⚠️ Failed to load package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = isDisplayVerySmallDesktop(context);
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).canvasColor,
        title: Text('About Qur\'ān Hadith'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.circleXmark),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 18,
          )
        ],
        bottom: TabBar(
          tabs: tabs,
          isScrollable: true,
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          splashBorderRadius: BorderRadius.circular(20),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppTab(context, isSmall, theme),
          _buildAuthorTab(context, isSmall, theme),
          _buildLicenseTab(context, theme),
        ],
      ),
    );
  }

  Widget _buildAppTab(BuildContext context, bool isSmall, TextTheme theme) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withAlpha((0.15 * 255).round()),
                primary.withAlpha((0.05 * 255).round()),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Theme.of(context).dividerColor.withAlpha((0.2 * 255).round()),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/Logo.png',
                  height: isSmall ? 54 : 72,
                  width: isSmall ? 54 : 72,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qur’ān Hadith',
                        style: theme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      _info == null
                          ? '—'
                          : 'Version ${_info!.version} (build ${_info!.buildNumber})',
                      style: theme.titleMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => launchUrl(
                    Uri.parse('https://github.com/kherldhussein/quran_hadith')),
                icon: const FaIcon(FontAwesomeIcons.github, size: 16),
                label: const Text('GitHub'),
              )
            ],
          ),
        ),

        const SizedBox(height: 16),

        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About', style: theme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Qur’ān Hadith helps you read, listen, and search the Qur’ān and browse Hadith collections with a clean, desktop-friendly experience. It supports offline favorites, resume reading/listening, and adaptive theming.',
                  style: theme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(
                          'https://github.com/kherldhussein/quran_hadith')),
                      icon: const FaIcon(FontAwesomeIcons.github, size: 16),
                      label: const Text('Repository'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final diagnostics = _diagnosticsString();
                        await Clipboard.setData(
                            ClipboardData(text: diagnostics));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Diagnostics copied')),
                          );
                        }
                      },
                      icon: const FaIcon(FontAwesomeIcons.copy, size: 14),
                      label: const Text('Copy diagnostics'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _LinkButton(
              icon: FontAwesomeIcons.bug,
              label: 'Report a Bug',
              url: 'https://github.com/kherldhussein/quran_hadith/issues/',
            ),
            _LinkButton(
              icon: FontAwesomeIcons.lightbulb,
              label: 'Request Feature',
              url: 'https://github.com/kherldhussein/quran_hadith/issues/',
            ),
            _LinkButton(
              icon: FontAwesomeIcons.heart,
              label: 'Support',
              url: 'https://www.patreon.com/join/kherld/checkout?ru=undefined',
            ),
          ],
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System', style: theme.titleLarge),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: FontAwesomeIcons.desktop,
                  label: 'Platform',
                  value: _platformString(),
                ),
                const SizedBox(height: 6),
                const _InfoRow(
                  icon: FontAwesomeIcons.gear,
                  label: 'Mode',
                  value: kReleaseMode ? 'Release' : 'Debug/Profile',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLicenseTab(BuildContext context, TextTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Text(
            'Qur’ān Hadith is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nQur’ān Hadith is distributed in the hope that it will be useful In Sha Allah. You should have received a copy of the GNU General Public License along with this program. If not, see',
            style: theme.titleLarge,
          ),
          InkWell(
            splashColor: Theme.of(context).scaffoldBackgroundColor,
            hoverColor: Theme.of(context).scaffoldBackgroundColor,
            highlightColor: Theme.of(context).scaffoldBackgroundColor,
            child: Text(
              'http://www.gnu.org/licenses/',
              style: theme.titleLarge!.copyWith(color: kLinkC),
            ),
            onTap: () => launchUrl(Uri.parse('http://www.gnu.org/licenses/')),
          ),
        ],
      ),
    );
  }

  String _platformString() {
    if (kIsWeb) return 'Web';
    try {
      return '${Platform.operatingSystem} ${Platform.version.split(' ').first}';
    } catch (e) {
      debugPrint('⚠️ Failed to get platform info: $e');
      return 'Unknown';
    }
  }

  Widget _buildAuthorTab(BuildContext context, bool isSmall, TextTheme theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Author', style: theme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.user, size: 14),
                    const SizedBox(width: 8),
                    Text('Khalid Hussein', style: theme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () =>
                      launchUrl(Uri.parse('mailto:kherld.hussein@gmail.com')),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.envelope, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'kherld.hussein@gmail.com',
                        style: theme.titleMedium?.copyWith(
                            color: kLinkC,
                            decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _diagnosticsString() {
    final v = _info == null
        ? '—'
        : 'Version ${_info!.version} (build ${_info!.buildNumber})';
    final p = _platformString();
    const mode = kReleaseMode ? 'Release' : 'Debug/Profile';
    return 'Qur’ān Hadith\n$v\nPlatform: $p\nMode: $mode';
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  const _LinkButton(
      {required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                Theme.of(context).dividerColor.withAlpha((0.2 * 255).round()),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 16),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Row(
      children: [
        FaIcon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: theme.titleMedium),
        const Spacer(),
        Text(value,
            style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
