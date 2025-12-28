import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/models/reciter_model.dart';
import 'package:quran_hadith/services/reciter_service.dart';
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/utils/sp_util.dart';

class AudioSettingsScreen extends StatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  bool _loading = true;

  String _selectedReciterId = 'ar.alafasy';
  List<Reciter> _reciters = const [];
  bool _recitersLoading = false;
  String? _reciterError;
  DateTime? _recitersCachedAt;

  double _playbackSpeed = 1.0;
  bool _autoPlay = false;
  bool _showTranslationWhilePlaying = true;
  String _audioQuality = 'high';
  String _repeatMode = 'none';
  bool _downloadForOffline = false;
  bool _downloadOverWifiOnly = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await appSP.init();
    await _loadSettings();
    await _fetchReciters();
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadSettings() async {
    final storedReciter =
        appSP.getString('selectedReciter', defaultValue: _selectedReciterId);
    final storedSpeed = appSP.getDouble('playbackSpeed', defaultValue: 1.0);
    final storedAutoPlay = SpUtil.getAutoPlayNextAyah();
    final storedTranslation = appSP.getBool(
      'showTranslationWhilePlaying',
      defaultValue: true,
    );
    final storedQuality = appSP.getString('audioQuality', defaultValue: 'high');
    final storedRepeat = appSP.getString('repeatMode', defaultValue: 'none');
    final storedDownload =
        appSP.getBool('downloadForOffline', defaultValue: false);
    final storedWifi =
        appSP.getBool('downloadOverWifiOnly', defaultValue: true);

    _selectedReciterId =
        storedReciter.isNotEmpty ? storedReciter : _selectedReciterId;
    _playbackSpeed = storedSpeed;
    _autoPlay = storedAutoPlay;
    await SpUtil.setAutoPlayNextAyah(_autoPlay);
    _showTranslationWhilePlaying = storedTranslation;
    _audioQuality = storedQuality;
    _repeatMode = storedRepeat;
    _downloadForOffline = storedDownload;
    _downloadOverWifiOnly = storedWifi;
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (value is bool) {
      await appSP.setBool(key, value);
      if (key == 'autoPlay') {
        await SpUtil.setAutoPlayNextAyah(value);
      }
    } else if (value is double) {
      await appSP.setDouble(key, value);
    } else if (value is int) {
      await appSP.setInt(key, value);
    } else if (value is String) {
      await appSP.setString(key, value);
    }
  }

  Future<void> _fetchReciters({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _recitersLoading = true;
      if (forceRefresh) {
        _reciterError = null;
      }
    });

    try {
      final reciters =
          await ReciterService.instance.getReciters(forceRefresh: forceRefresh);

      if (!mounted) return;
      setState(() {
        _reciters = reciters;
        _recitersCachedAt = ReciterService.instance.lastFetched;
        _recitersLoading = false;
        if (reciters.isEmpty) {
          _reciterError = 'No reciters available right now.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recitersLoading = false;
        _reciterError =
            'Unable to refresh the catalog. Showing the fallback list.';
        if (_reciters.isEmpty) {
          _reciters = Reciter.fallback;
        }
      });
    }
  }

  Reciter _resolveSelectedReciter() {
    if (_reciters.isNotEmpty) {
      try {
        return _reciters
            .firstWhere((reciter) => reciter.id == _selectedReciterId);
      } catch (_) {}
    }
    return ReciterService.instance
        .resolveById(_selectedReciterId, within: _reciters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Settings'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchReciters(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildReciterSection(theme),
            _buildPlaybackSection(theme),
            _buildDownloadSection(theme),
            _buildAdvancedSection(theme),
            _buildActionsSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildReciterSection(ThemeData theme) {
    final selectedReciter = _resolveSelectedReciter();
    final cacheLabel = _formatCacheLabel();

    return _buildSection(
      theme: theme,
      title: 'Reciter',
      icon: FontAwesomeIcons.user,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FontAwesomeIcons.user,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedReciter.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedReciter.arabicName ?? selectedReciter.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontFamily: 'Amiri',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          selectedReciter.styleLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  FontAwesomeIcons.chevronRight,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(FontAwesomeIcons.rotate, size: 16),
              label: const Text('Change Reciter'),
              onPressed: () => _showReciterPicker(theme),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
          if (_recitersLoading) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Refreshing reciters…',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ],
          if (_reciterError != null) ...[
            const SizedBox(height: 8),
            Text(
              _reciterError!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            (selectedReciter.description?.isNotEmpty ?? false)
                ? selectedReciter.description!
                : 'Explore different reciters to find the voice that resonates with you.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          if (cacheLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              cacheLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaybackSection(ThemeData theme) {
    return _buildSection(
      theme: theme,
      title: 'Playback',
      icon: FontAwesomeIcons.music,
      child: Column(
        children: [
          _buildSliderSetting(
            theme: theme,
            label: 'Playback Speed',
            value: _playbackSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) async {
              setState(() =>
                  _playbackSpeed = double.parse(value.toStringAsFixed(1)));
              await _saveSetting('playbackSpeed', _playbackSpeed);
            },
            valueLabel: '${_playbackSpeed.toStringAsFixed(1)}x',
          ),
          const SizedBox(height: 16),
          _buildSwitchSetting(
            theme: theme,
            title: 'Auto play next ayah',
            subtitle: 'Continue recitation without manual input.',
            icon: FontAwesomeIcons.forwardStep,
            value: _autoPlay,
            onChanged: (value) async {
              setState(() => _autoPlay = value);
              await _saveSetting('autoPlay', value);
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchSetting(
            theme: theme,
            title: 'Show translation while playing',
            subtitle: 'Display the selected translation alongside audio.',
            icon: FontAwesomeIcons.language,
            value: _showTranslationWhilePlaying,
            onChanged: (value) async {
              setState(() => _showTranslationWhilePlaying = value);
              await _saveSetting('showTranslationWhilePlaying', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection(ThemeData theme) {
    return _buildSection(
      theme: theme,
      title: 'Offline Access',
      icon: FontAwesomeIcons.cloudArrowDown,
      child: Column(
        children: [
          _buildSwitchSetting(
            theme: theme,
            title: 'Download for offline playback',
            subtitle: 'Store recitations locally to listen without internet.',
            icon: FontAwesomeIcons.downLong,
            value: _downloadForOffline,
            onChanged: (value) async {
              setState(() => _downloadForOffline = value);
              await _saveSetting('downloadForOffline', value);
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchSetting(
            theme: theme,
            title: 'Download on Wi-Fi only',
            subtitle: 'Avoid mobile data usage while fetching audio files.',
            icon: FontAwesomeIcons.wifi,
            value: _downloadOverWifiOnly,
            onChanged: (value) async {
              setState(() => _downloadOverWifiOnly = value);
              await _saveSetting('downloadOverWifiOnly', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection(ThemeData theme) {
    return _buildSection(
      theme: theme,
      title: 'Advanced',
      icon: FontAwesomeIcons.sliders,
      child: Column(
        children: [
          _buildDropdownSetting(
            theme: theme,
            title: 'Audio Quality',
            icon: FontAwesomeIcons.waveSquare,
            value: _audioQuality,
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Low (64 kbps)')),
              DropdownMenuItem(
                  value: 'medium', child: Text('Medium (96 kbps)')),
              DropdownMenuItem(value: 'high', child: Text('High (128 kbps)')),
              DropdownMenuItem(
                  value: 'lossless', child: Text('Lossless (FLAC)')),
            ],
            onChanged: (value) async {
              if (value == null) return;
              setState(() => _audioQuality = value);
              await _saveSetting('audioQuality', value);
            },
          ),
          const SizedBox(height: 16),
          _buildDropdownSetting(
            theme: theme,
            title: 'Repeat Mode',
            icon: FontAwesomeIcons.repeat,
            value: _repeatMode,
            items: const [
              DropdownMenuItem(value: 'none', child: Text('None')),
              DropdownMenuItem(value: 'ayah', child: Text('Repeat Ayah')),
              DropdownMenuItem(value: 'surah', child: Text('Repeat Surah')),
            ],
            onChanged: (value) async {
              if (value == null) return;
              setState(() => _repeatMode = value);
              await _saveSetting('repeatMode', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ThemeData theme) {
    return _buildSection(
      theme: theme,
      title: 'Maintenance',
      icon: FontAwesomeIcons.toolbox,
      child: Column(
        children: [
          _buildActionButton(
            theme: theme,
            icon: FontAwesomeIcons.eraser,
            label: 'Clear downloaded audio',
            subtitle: 'Remove all cached recitations from this device.',
            color: theme.colorScheme.error,
            onTap: () => _clearCache(theme),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            theme: theme,
            icon: FontAwesomeIcons.arrowRotateLeft,
            label: 'Reset to defaults',
            subtitle: 'Restore the recommended audio experience.',
            color: theme.colorScheme.primary,
            onTap: () => _resetToDefaults(theme),
          ),
        ],
      ),
    );
  }

  Future<void> _showReciterPicker(ThemeData theme) async {
    if (_reciters.isEmpty && !_recitersLoading) {
      await _fetchReciters();
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final catalog = _reciters.isNotEmpty ? _reciters : Reciter.fallback;
            final isLoading = _recitersLoading;

            Future<void> handleRefresh() async {
              await _fetchReciters(forceRefresh: true);
              if (mounted) {
                modalSetState(() {});
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        Icon(FontAwesomeIcons.users,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Select Reciter',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          onPressed: isLoading ? null : handleRefresh,
                        ),
                      ],
                    ),
                  ),
                  if (_reciterError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        _reciterError!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            itemCount: catalog.length,
                            itemBuilder: (context, index) {
                              final reciter = catalog[index];
                              final isSelected =
                                  reciter.id == _selectedReciterId;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                          .withValues(alpha: 0.1)
                                      : theme
                                          .colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.primary
                                              .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      FontAwesomeIcons.user,
                                      color: isSelected
                                          ? Colors.white
                                          : theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    reciter.displayName,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (reciter.arabicName != null &&
                                          reciter.arabicName!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            reciter.arabicName!,
                                            style: TextStyle(
                                              fontFamily: 'Amiri',
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              reciter.styleLabel.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          if (reciter.language != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              reciter.language!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (reciter.description != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            reciter.description!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    isSelected
                                        ? FontAwesomeIcons.circleCheck
                                        : FontAwesomeIcons.circle,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.3),
                                    size: 18,
                                  ),
                                  onTap: () {
                                    if (!mounted) return;

                                    // Update UI immediately
                                    setState(() {
                                      _selectedReciterId = reciter.id;
                                    });
                                    modalSetState(() {});

                                    // Update ReciterService immediately (notifies all listeners)
                                    ReciterService.instance
                                        .setCurrentReciterId(reciter.id);

                                    // Close modal immediately
                                    Navigator.of(context).pop();

                                    // Save to storage asynchronously without blocking UI
                                    _saveSetting('selectedReciter', reciter.id)
                                        .then((_) => SpUtil.setReciter(reciter.id));

                                    // Show feedback
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Reciter changed to ${reciter.displayName}',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
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

  Widget _buildSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? theme.colorScheme.primary
                : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required ThemeData theme,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                valueLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          underline: Container(),
          icon: Icon(
            FontAwesomeIcons.chevronDown,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              FontAwesomeIcons.chevronRight,
              size: 14,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  String? _formatCacheLabel() {
    final fetchedAt = _recitersCachedAt;
    if (fetchedAt == null) return null;
    final difference = DateTime.now().difference(fetchedAt);

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes.clamp(1, 59);
      return 'Updated $minutes minute${minutes == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours.clamp(1, 23);
      return 'Updated $hours hour${hours == 1 ? '' : 's'} ago';
    }
    final days = difference.inDays;
    return 'Updated $days day${days == 1 ? '' : 's'} ago';
  }

  void _clearCache(ThemeData theme) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Audio Cache'),
        content: const Text(
          'This will remove all cached audio files. You can download them again at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Audio cache cleared'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults(ThemeData theme) async {
    setState(() {
      _selectedReciterId = 'ar.alafasy';
      _playbackSpeed = 1.0;
      _autoPlay = false;
      _showTranslationWhilePlaying = true;
      _audioQuality = 'high';
      _repeatMode = 'none';
      _downloadForOffline = false;
      _downloadOverWifiOnly = true;
    });

    await Future.wait([
      _saveSetting('selectedReciter', _selectedReciterId),
      SpUtil.setReciter(_selectedReciterId),
      _saveSetting('playbackSpeed', _playbackSpeed),
      _saveSetting('autoPlay', _autoPlay),
      _saveSetting(
        'showTranslationWhilePlaying',
        _showTranslationWhilePlaying,
      ),
      _saveSetting('audioQuality', _audioQuality),
      _saveSetting('repeatMode', _repeatMode),
      _saveSetting('downloadForOffline', _downloadForOffline),
      _saveSetting('downloadOverWifiOnly', _downloadOverWifiOnly),
    ]);

    // Persist reciter to storage
    await appSP.setString('selectedReciter', _selectedReciterId);
    await SpUtil.setReciter(_selectedReciterId);
    ReciterService.instance.setCurrentReciterId(_selectedReciterId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audio settings reset to defaults'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
