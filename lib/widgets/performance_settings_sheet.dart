import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/services/performance_service.dart';

/// Performance settings sheet
class PerformanceSettingsSheet extends StatelessWidget {
  final PerformanceService service;

  const PerformanceSettingsSheet({super.key, required this.service});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PerformanceSettingsSheet(service: performanceService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildHeader(context, theme),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildOptimizationToggles(theme),
                        const SizedBox(height: 16),
                        _buildPreloadSettings(theme),
                        const SizedBox(height: 16),
                        _buildCacheSettings(theme),
                        const SizedBox(height: 16),
                        _buildPerformanceMetrics(theme),
                        const SizedBox(height: 16),
                        _buildActions(context, theme),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.gaugeHigh, size: 20),
          const SizedBox(width: 12),
          Text(
            'Performance Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationToggles(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Optimizations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildToggle(
            theme,
            'Image Caching',
            'Cache surah header images for faster loading',
            FontAwesomeIcons.image,
            service.enableImageCaching,
            () => service.toggleImageCaching(),
          ),
          _buildToggle(
            theme,
            'Audio Preloading',
            'Preload next ayah audio for seamless playback',
            FontAwesomeIcons.volumeHigh,
            service.enableAudioPreloading,
            () => service.toggleAudioPreloading(),
          ),
          _buildToggle(
            theme,
            'Virtual Scrolling',
            'Use virtual scrolling for long surahs',
            FontAwesomeIcons.scroll,
            service.enableVirtualScrolling,
            () => service.toggleVirtualScrolling(),
          ),
          _buildToggle(
            theme,
            'Lazy Translations',
            'Load translations on demand',
            FontAwesomeIcons.language,
            service.enableLazyTranslations,
            () => service.toggleLazyTranslations(),
          ),
          _buildToggle(
            theme,
            'Memory Optimization',
            'Automatically manage memory and caches',
            FontAwesomeIcons.microchip,
            service.enableMemoryOptimization,
            () => service.toggleMemoryOptimization(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    VoidCallback onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      secondary: FaIcon(icon, size: 16),
      value: value,
      onChanged: (_) => onChanged(),
    );
  }

  Widget _buildPreloadSettings(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preload Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preload Distance',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Number of ayahs to preload',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${service.preloadDistance}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: service.preloadDistance.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${service.preloadDistance}',
              onChanged: service.enableAudioPreloading
                  ? (value) => service.setPreloadDistance(value.toInt())
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheSettings(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Max Cache Size',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Maximum memory for caches',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(service.getPerformanceReport()['memory']['maxCacheSizeMB'])} MB',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: (service.getPerformanceReport()['memory']['maxCacheSizeMB'] as int).toDouble(),
              min: 50,
              max: 500,
              divisions: 45,
              label: '${service.getPerformanceReport()['memory']['maxCacheSizeMB']} MB',
              onChanged: service.enableMemoryOptimization
                  ? (value) => service.setMaxCacheSize(value.toInt())
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(ThemeData theme) {
    final report = service.getPerformanceReport();
    final imageCache = report['imageCache'] as Map<String, dynamic>;
    final audioPreload = report['audioPreload'] as Map<String, dynamic>;
    final translationCache = report['translationCache'] as Map<String, dynamic>;
    final performance = report['performance'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.chartLine,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Metrics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetric(
              theme,
              'Image Cache',
              '${imageCache['size']} images',
              FontAwesomeIcons.image,
            ),
            _buildMetric(
              theme,
              'Audio Preloaded',
              '${audioPreload['preloadedCount']} ayahs',
              FontAwesomeIcons.volumeHigh,
            ),
            _buildMetric(
              theme,
              'Translation Cache',
              '${translationCache['size']} translations',
              FontAwesomeIcons.language,
            ),
            _buildMetric(
              theme,
              'Average Frame Rate',
              '${performance['averageFrameRate']} FPS',
              FontAwesomeIcons.gaugeHigh,
            ),
            _buildMetric(
              theme,
              'Jank Count',
              '${performance['jankCount']} frames',
              FontAwesomeIcons.triangleExclamation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: FaIcon(
                icon,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await service.clearAllCaches();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All caches cleared')),
                  );
                }
              },
              icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
              label: const Text('Clear All Caches'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
