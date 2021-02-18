import 'package:flutter/material.dart';
import 'package:quran_hadith/theme/theme_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFFAFAFC).withOpacity(0.2),
            border: Border.all(color: Theme.of(context).backgroundColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView(
            children: [
              AppBar(
                title: Text('Preferences'),
                backgroundColor: Colors.transparent,
              ),
              SettingsTitle(title: 'General'),
              SettingsButton(
                title: 'Dark Theme',
                subtitle: 'Switch to join the dark side',
                value: ThemeState.isDarkMode,
                onChanged: (value) => SettingsModel().updateAppTheme(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSpacer extends StatelessWidget {
  const SettingsSpacer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SizedBox(height: 8);
}

class SettingsTitle extends StatelessWidget {
  final String title;

  const SettingsTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.fromLTRB(6, 8, 6, 8), child: Text(title));
  }
}

class SettingsButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsButton({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

ThemeState themeState = ThemeState();

class SettingsModel extends ChangeNotifier {
  updateAppTheme(BuildContext context) async {
    bool boolVal = !ThemeState.isDarkMode;
    themeState.updateTheme(boolVal);
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool('isdarkmode', boolVal);
    notifyListeners();
  }
}
