import 'package:flutter/material.dart';
import 'package:quran_hadith/theme/theme_state.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                Switch(value: ThemeState().isDarkMode, onChanged: (v) {
                  setState(() {
                    ThemeState().updateTheme(ThemeData.light());
                  });
                }),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ActionChip(
                      label: Text('Light'),
                      backgroundColor: theme.chipTheme.backgroundColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.background),
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20)),
                      ),
                      onPressed: () =>
                          ThemeState().updateTheme(ThemeData.light()),
                    ),
                    // ActionChip(
                    //   label: Text('System Theme'),
                    //   tooltip: 'On supported device only',
                    //   onPressed: () =>
                    //       ThemeState().updateTheme(ThemeData.dark()),
                    // ),
                    ActionChip(
                      label: Text('Dark'),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.background),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20)),
                      ),
                      onPressed: () =>
                          ThemeState().updateTheme(ThemeData.dark()),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
