import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:quran_hadith/services/theme_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Theme builder and management screen
class ThemeBuilderScreen extends StatefulWidget {
  final CustomTheme? editingTheme;

  const ThemeBuilderScreen({super.key, this.editingTheme});

  @override
  State<ThemeBuilderScreen> createState() => _ThemeBuilderScreenState();
}

class _ThemeBuilderScreenState extends State<ThemeBuilderScreen> {
  late CustomTheme _theme;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _theme = widget.editingTheme ?? CustomTheme.classic();
    _nameController.text = _theme.name;
    _descriptionController.text = _theme.description;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.editingTheme == null ? 'Create Theme' : 'Edit Theme'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.floppyDisk),
            onPressed: _saveTheme,
            tooltip: 'Save Theme',
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.fileExport),
            onPressed: _exportTheme,
            tooltip: 'Export Theme',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBasicInfo(theme),
          const SizedBox(height: 16),
          _buildColorSection(theme),
          const SizedBox(height: 16),
          _buildArabicTextSection(theme),
          const SizedBox(height: 16),
          _buildTypographySection(theme),
          const SizedBox(height: 16),
          _buildLayoutSection(theme),
          const SizedBox(height: 16),
          _buildBackgroundSection(theme),
          const SizedBox(height: 16),
          _buildPreview(theme),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Theme Name',
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Dark Theme'),
              subtitle:
                  const Text('Use dark colors for low-light environments'),
              value: _theme.isDark,
              onChanged: (value) {
                setState(() {
                  _theme = _theme.copyWith(isDark: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Colors',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildColorPicker('Primary Color', _theme.primaryColor, (color) {
              setState(() => _theme = _theme.copyWith(primaryColor: color));
            }),
            _buildColorPicker('Accent Color', _theme.accentColor, (color) {
              setState(() => _theme = _theme.copyWith(accentColor: color));
            }),
            _buildColorPicker('Background Color', _theme.backgroundColor,
                (color) {
              setState(() => _theme = _theme.copyWith(backgroundColor: color));
            }),
            _buildColorPicker('Card Color', _theme.cardColor, (color) {
              setState(() => _theme = _theme.copyWith(cardColor: color));
            }),
            _buildColorPicker('App Bar Color', _theme.appBarColor, (color) {
              setState(() => _theme = _theme.copyWith(appBarColor: color));
            }),
            _buildColorPicker('Text Color', _theme.textColor, (color) {
              setState(() => _theme = _theme.copyWith(textColor: color));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(
      String label, Color currentColor, ValueChanged<Color> onColorChanged) {
    return ListTile(
      title: Text(label),
      trailing: GestureDetector(
        onTap: () => _showColorPicker(label, currentColor, onColorChanged),
        child: Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(
      String label, Color currentColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick $label'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicTextSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arabic Text',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildColorPicker('Arabic Text Color', _theme.arabicTextColor,
                (color) {
              setState(() => _theme = _theme.copyWith(arabicTextColor: color));
            }),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Arabic Font Size'),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: _theme.arabicFontSize,
                  min: 16,
                  max: 48,
                  divisions: 32,
                  label: '${_theme.arabicFontSize.toInt()}',
                  onChanged: (value) {
                    setState(
                        () => _theme = _theme.copyWith(arabicFontSize: value));
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Preview'),
              subtitle: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontFamily: _theme.arabicFontFamily,
                  fontSize: _theme.arabicFontSize,
                  color: _theme.arabicTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypographySection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Typography',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _theme.bodyFontFamily,
              decoration: const InputDecoration(
                labelText: 'Body Font',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                DropdownMenuItem(
                    value: 'OpenDyslexic', child: Text('OpenDyslexic')),
                DropdownMenuItem(value: 'Lato', child: Text('Lato')),
                DropdownMenuItem(
                    value: 'Merriweather', child: Text('Merriweather')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(
                      () => _theme = _theme.copyWith(bodyFontFamily: value));
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _theme.headingFontFamily,
              decoration: const InputDecoration(
                labelText: 'Heading Font',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                DropdownMenuItem(
                    value: 'OpenDyslexic', child: Text('OpenDyslexic')),
                DropdownMenuItem(value: 'Lato', child: Text('Lato')),
                DropdownMenuItem(
                    value: 'Merriweather', child: Text('Merriweather')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(
                      () => _theme = _theme.copyWith(headingFontFamily: value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Layout',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Border Radius'),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: _theme.borderRadius,
                  min: 0,
                  max: 24,
                  divisions: 24,
                  label: '${_theme.borderRadius.toInt()}',
                  onChanged: (value) {
                    setState(
                        () => _theme = _theme.copyWith(borderRadius: value));
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Elevation'),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: _theme.elevation,
                  min: 0,
                  max: 8,
                  divisions: 8,
                  label: '${_theme.elevation.toInt()}',
                  onChanged: (value) {
                    setState(() => _theme = _theme.copyWith(elevation: value));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Background',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<BackgroundStyle>(
              segments: const [
                ButtonSegment(
                  value: BackgroundStyle.solid,
                  label: Text('Solid'),
                  icon: Icon(Icons.color_lens),
                ),
                ButtonSegment(
                  value: BackgroundStyle.gradient,
                  label: Text('Gradient'),
                  icon: Icon(Icons.gradient),
                ),
              ],
              selected: {_theme.backgroundStyle},
              onSelectionChanged: (Set<BackgroundStyle> newSelection) {
                setState(() {
                  _theme = _theme.copyWith(backgroundStyle: newSelection.first);
                });
              },
            ),
            if (_theme.backgroundStyle == BackgroundStyle.gradient) ...[
              const SizedBox(height: 16),
              const Text('Gradient Colors'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildGradientColorButton(0),
                  _buildGradientColorButton(1),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradientColorButton(int index) {
    final colors = _theme.gradientColors ??
        [_theme.backgroundColor, _theme.backgroundColor];
    final color =
        index < colors.length ? colors[index] : _theme.backgroundColor;

    return GestureDetector(
      onTap: () {
        _showColorPicker('Gradient Color ${index + 1}', color, (newColor) {
          setState(() {
            final newColors = List<Color>.from(colors);
            if (index < newColors.length) {
              newColors[index] = newColor;
            } else {
              newColors.add(newColor);
            }
            _theme = _theme.copyWith(gradientColors: newColors);
          });
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Center(
          child:
              Text('${index + 1}', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _theme.backgroundColor,
                borderRadius: BorderRadius.circular(_theme.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _theme.primaryColor,
                      borderRadius: BorderRadius.circular(_theme.borderRadius),
                    ),
                    child: Text(
                      'Primary Element',
                      style: TextStyle(color: _theme.textOnPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _theme.cardColor,
                      borderRadius: BorderRadius.circular(_theme.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: _theme.elevation * 2,
                          offset: Offset(0, _theme.elevation),
                        ),
                      ],
                    ),
                    child: Text(
                      'Card Element',
                      style: TextStyle(color: _theme.textColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    style: TextStyle(
                      fontFamily: _theme.arabicFontFamily,
                      fontSize: _theme.arabicFontSize,
                      color: _theme.arabicTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTheme() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Error', 'Theme name cannot be empty');
      return;
    }

    final newTheme = _theme.copyWith(name: name, description: description);
    await themeService.saveTheme(newTheme);

    Get.snackbar('Success', 'Theme saved successfully');
    Get.back();
  }

  void _exportTheme() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final themeToExport = _theme.copyWith(name: name, description: description);

    final jsonString = themeService.exportTheme(themeToExport);

    Clipboard.setData(ClipboardData(text: jsonString));
    Get.snackbar(
      'Exported',
      'Theme JSON copied to clipboard',
      snackPosition: SnackPosition.bottom,
    );
  }
}
