import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_hadith/theme/app_theme.dart';
import 'package:quran_hadith/theme/theme_state.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ThemeState themes = Provider.of<ThemeState>(context);
    return Scaffold(
      backgroundColor: theme.appBarTheme.backgroundColor,
      body: Center(
        child: Container(
          width: 400,
          height: 250,
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(color: theme.colorScheme.background),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppBar(
                  title: Text(
                    'Preferences',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(6, 8, 6, 8),
                  child: Text('Customize Your Experience'),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(6, 8, 6, 8),
                  child: Text('Switch to join the dark side'),
                ),
                Switch(
                    value: themes.isDarkMode,
                    activeColor: kAccentColor,
                    inactiveTrackColor: kAccentColor.withOpacity(.5),
                    onChanged: (bool val) {
                      setState(() {
                        themes.updateTheme();
                      });
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
