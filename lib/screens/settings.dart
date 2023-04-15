import 'package:flutter/material.dart';
import 'package:quran_hadith/theme/theme_state.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: Center(
        child: Container(
          width: 400,
          height: 250,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).colorScheme.background),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppBar(
                  title: Text(
                    'Preferences',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(6, 8, 6, 8),
                  child: Text('Customize Your Experience'),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ActionChip(
                      label: Text('Light'),
                      backgroundColor:
                          Theme.of(context).chipTheme.backgroundColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.background),
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20)),
                      ),
                      onPressed: () =>
                          ThemeState.to.updateTheme(ThemeMode.light),
                    ),
                    ActionChip(
                      label: Text('System Theme'),
                      tooltip: 'On supported device only',
                      onPressed: () =>
                          ThemeState.to.updateTheme(ThemeMode.system),
                    ),
                    ActionChip(
                      label: Text('Dark'),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.background),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20)),
                      ),
                      onPressed: () =>
                          ThemeState.to.updateTheme(ThemeMode.dark),
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
