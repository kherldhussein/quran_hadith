import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/database/database_service.dart';
import 'package:quran_hadith/database/hive_adapters.dart';
import 'package:quran_hadith/theme/theme_state.dart';
import 'package:quran_hadith/utils/sp_util.dart';
import 'package:quran_hadith/utils/shared_p.dart';
import 'package:quran_hadith/services/reciter_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:quran_hadith/screens/audio_settings.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late UserPreferences _preferences;
  late TextEditingController _userNameController;
  bool _isLoading = true;
  Map<String, dynamic>? _storageStats;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      _preferences = database.getPreferences();
      _userNameController = TextEditingController(text: _preferences.userName);

      _storageStats = await database.getStorageStats();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      _preferences = UserPreferences();
      _userNameController = TextEditingController(text: 'Guest');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _savePreferences() async {
    try {
      await database.savePreferences(_preferences);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeState>(
      builder: (context, themeState, _) {
        final theme = Theme.of(context);

        if (_isLoading) {
          return Scaffold(
            backgroundColor: theme.appBarTheme.backgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: theme.appBarTheme.backgroundColor,
          body: Row(
            children: [
              Container(
                width: 240,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    right:
                        BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                  ),
                ),
                child: _buildSettingsNav(theme),
              ),
              Expanded(
                child: _buildSettingsContent(theme, themeState),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsNav(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),
        _buildNavItem(
          icon: FontAwesomeIcons.userCircle,
          title: 'General',
          theme: theme,
        ),
        _buildNavItem(
          icon: FontAwesomeIcons.paintbrush,
          title: 'Appearance',
          theme: theme,
        ),
        _buildNavItem(
          icon: FontAwesomeIcons.volumeHigh,
          title: 'Audio',
          theme: theme,
        ),
        _buildNavItem(
          icon: FontAwesomeIcons.language,
          title: 'Reading',
          theme: theme,
        ),
        _buildNavItem(
          icon: FontAwesomeIcons.bell,
          title: 'Notifications',
          theme: theme,
        ),
        _buildNavItem(
          icon: FontAwesomeIcons.database,
          title: 'Data & Storage',
          theme: theme,
        ),
        _buildNavItem(
          icon: FontAwesomeIcons.keyboard,
          title: 'Shortcuts',
          theme: theme,
        ),
        _buildNavItem(
          icon: FontAwesomeIcons.circleInfo,
          title: 'About',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: FaIcon(icon, size: 18, color: theme.colorScheme.primary),
      title: Text(title),
      onTap: () {},
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildSettingsContent(ThemeData theme, ThemeState themeState) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        _buildSection(
          title: 'General Settings',
          icon: FontAwesomeIcons.gear,
          theme: theme,
          children: [
            _buildTextField(
              label: 'User Name',
              controller: _userNameController,
              onChanged: (value) {
                _preferences.userName = value;
                _savePreferences();
                SpUtil.setUser(value);
              },
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildDropdown<String>(
              label: 'Language',
              value: _preferences.language,
              items: [
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'ar', child: Text('العربية')),
                const DropdownMenuItem(value: 'ur', child: Text('اردو')),
                const DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
              ],
              onChanged: (value) {
                setState(() => _preferences.language = value!);
                _savePreferences();
              },
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: 'Appearance',
          icon: FontAwesomeIcons.paintbrush,
          theme: theme,
          children: [
            _buildSwitchTile(
              title: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              value: _preferences.isDarkMode,
              onChanged: (value) async {
                setState(() => _preferences.isDarkMode = value);
                await SpUtil.setThemed(value);
                themeState.setTheme(value);
                await _savePreferences();
              },
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'Font Size',
              value: _preferences.fontSize,
              min: 16.0,
              max: 36.0,
              divisions: 20,
              onChanged: (value) {
                setState(() => _preferences.fontSize = value);
              },
              onChangeEnd: (value) {
                _savePreferences();
              },
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildDropdown<String>(
              label: 'Font Family',
              value: _preferences.fontFamily,
              items: [
                const DropdownMenuItem(value: 'Amiri', child: Text('Amiri')),
                const DropdownMenuItem(
                    value: 'Poppins', child: Text('Poppins')),
                const DropdownMenuItem(
                    value: 'System', child: Text('System Default')),
              ],
              onChanged: (value) {
                setState(() => _preferences.fontFamily = value!);
                _savePreferences();
              },
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: 'Audio Settings',
          icon: FontAwesomeIcons.volumeHigh,
          theme: theme,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.headphones,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Advanced Audio Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure reciters, playback speed, repeat modes, and more',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(FontAwesomeIcons.sliders, size: 16),
                      label: const Text('Open Audio Settings'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AudioSettingsScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdown<String>(
              label: 'Quick Reciter Select',
              value: _preferences.reciter,
              items: [
                const DropdownMenuItem(
                    value: 'ar.alafasy', child: Text('Mishary Alafasy')),
                const DropdownMenuItem(
                    value: 'ar.abdulbasit', child: Text('Abdul Basit')),
                const DropdownMenuItem(
                    value: 'ar.husary',
                    child: Text('Mahmoud Khalil Al-Hussary')),
                const DropdownMenuItem(
                    value: 'ar.minshawi',
                    child: Text('Mohamed Siddiq El-Minshawi')),
                const DropdownMenuItem(
                    value: 'ar.muhammadayyoub', child: Text('Muhammad Ayyoub')),
              ],
              onChanged: (value) async {
                if (value == null || value.isEmpty) return;
                setState(() => _preferences.reciter = value);
                await SpUtil.setReciter(value);
                await appSP.setString('selectedReciter', value);
                ReciterService.instance.setCurrentReciterId(value);
                await _savePreferences();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reciter set to $value'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'Playback Speed',
              value: _preferences.playbackSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (value) {
                setState(() => _preferences.playbackSpeed = value);
              },
              onChangeEnd: (value) async {
                await SpUtil.setAudioSpeed(value);
                await _savePreferences();
              },
              theme: theme,
              displayValue: '${_preferences.playbackSpeed.toStringAsFixed(2)}x',
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: 'Reading Settings',
          icon: FontAwesomeIcons.bookOpen,
          theme: theme,
          children: [
            _buildSwitchTile(
              title: 'Show Translation',
              subtitle: 'Display translation alongside Arabic text',
              value: _preferences.showTranslation,
              onChanged: (value) {
                setState(() => _preferences.showTranslation = value);
                _savePreferences();
              },
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Auto Scroll',
              subtitle: 'Automatically scroll during audio playback',
              value: _preferences.autoScroll,
              onChanged: (value) async {
                setState(() => _preferences.autoScroll = value);
                await SpUtil.setAutoScroll(value);
                await _savePreferences();
              },
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: 'Notifications',
          icon: FontAwesomeIcons.bell,
          theme: theme,
          children: [
            _buildSwitchTile(
              title: 'Enable Notifications',
              subtitle: 'Receive reading reminders and updates',
              value: _preferences.enableNotifications,
              onChanged: (value) {
                setState(() => _preferences.enableNotifications = value);
                _savePreferences();
              },
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'System Tray',
              subtitle: 'Show app in system tray',
              value: _preferences.enableSystemTray,
              onChanged: (value) {
                setState(() => _preferences.enableSystemTray = value);
                _savePreferences();
              },
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: 'Data & Storage',
          icon: FontAwesomeIcons.database,
          theme: theme,
          children: [
            if (_storageStats != null) ...[
              _buildStorageInfo(theme),
              const SizedBox(height: 16),
            ],
            _buildActionButton(
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              icon: FontAwesomeIcons.trash,
              onTap: () => _showClearCacheDialog(theme),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              title: 'Export Data',
              subtitle: 'Backup your bookmarks and notes',
              icon: FontAwesomeIcons.fileExport,
              onTap: () => _exportData(),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              title: 'Import Data',
              subtitle: 'Restore from backup',
              icon: FontAwesomeIcons.fileImport,
              onTap: () => _importData(),
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: 'Keyboard Shortcuts',
          icon: FontAwesomeIcons.keyboard,
          theme: theme,
          children: [
            _buildSwitchTile(
              title: 'Enable Global Shortcuts',
              subtitle: 'Control app with keyboard shortcuts',
              value: _preferences.enableGlobalShortcuts,
              onChanged: (value) async {
                setState(() => _preferences.enableGlobalShortcuts = value);
                await _savePreferences();
              },
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildShortcutsList(theme),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          title: 'About',
          icon: FontAwesomeIcons.circleInfo,
          theme: theme,
          children: [
            const ListTile(
              title: Text('Version'),
              subtitle: Text('2.0.0'),
            ),
            const ListTile(
              title: Text('Developer'),
              subtitle: Text('Khalid Hussein'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const FaIcon(FontAwesomeIcons.github, size: 16),
              label: const Text('View on GitHub'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required ThemeData theme,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    required ThemeData theme,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required ThemeData theme,
  }) {
    final itemValues = items.map((item) => item.value).toList();
    final safeValue = itemValues.contains(value) ? value : itemValues.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: safeValue,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required ThemeData theme,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: theme.colorScheme.primary,
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required Function(double)? onChangeEnd,
    required ThemeData theme,
    String? displayValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              displayValue ?? value.toStringAsFixed(1),
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
          activeColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            FaIcon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color)),
                ],
              ),
            ),
            const FaIcon(FontAwesomeIcons.chevronRight, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildStorageStat(
              'Cached Surahs', '${_storageStats!['cachedSurahs']}'),
          const Divider(),
          _buildStorageStat('Bookmarks', '${_storageStats!['bookmarks']}'),
          const Divider(),
          _buildStorageStat('Study Notes', '${_storageStats!['studyNotes']}'),
          const Divider(),
          _buildStorageStat('Cache Size',
              '${_storageStats!['cacheSize']?.toStringAsFixed(2) ?? '0'} MB'),
        ],
      ),
    );
  }

  Widget _buildStorageStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildShortcutsList(ThemeData theme) {
    final shortcuts = [
      {'key': 'Space', 'action': 'Play/Pause'},
      {'key': 'Ctrl+F', 'action': 'Search'},
      {'key': 'Ctrl+B', 'action': 'Toggle Bookmark'},
      {'key': 'Ctrl+N', 'action': 'Add Note'},
      {'key': 'Left/Right', 'action': 'Skip 10 seconds'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: shortcuts.map((shortcut) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(shortcut['action']!),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    shortcut['key']!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showClearCacheDialog(ThemeData theme) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
            'This will delete all cached data. You can re-download it later.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await database.clearCachedSurahs();
      await _loadPreferences();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
    }
  }

  Future<void> _exportData() async {
    try {
      final data = await database.exportData();
      final jsonString = json.encode(data);

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Data',
        fileName:
            'quran_app_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsString(jsonString);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = json.decode(jsonString);

        await database.importData(data);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }
}
