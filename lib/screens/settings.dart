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
      backgroundColor: Theme.of(context).appBarTheme.color,
      body: Center(
        child: Container(
          width: 400,
          height: 250,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).backgroundColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppBar(
                  title: Text('Preferences'),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                SettingsTitle(title: 'Customize Your Experience'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ActionChip(
                      label: Text('Light'),
                      onPressed: () =>
                          ThemeState.to.updateTheme(ThemeMode.light),
                    ),
                    ActionChip(
                      label: Text('Dark'),
                      onPressed: () =>
                          ThemeState.to.updateTheme(ThemeMode.dark),
                    ),
                  ],
                ),
                /// Upgrade
                // Row(
                //   children: [
                //     Container(
                //       decoration: BoxDecoration(
                //         color: Theme.of(context).chipTheme.backgroundColor,
                //         borderRadius: BorderRadius.only(
                //             topLeft: Radius.circular(20),
                //             bottomLeft: Radius.circular(20)),
                //       ),
                //       child: Center(child: Text("Light")),width: 50,
                //     ),  SettingsTitle(title: 'Customize Your Experience'),  Container(
                //       decoration: BoxDecoration(
                //         color: Theme.of(context).primaryColorDark,
                //         borderRadius: BorderRadius.only(
                //             topRight: Radius.circular(20),
                //             bottomRight: Radius.circular(20)),
                //       ),
                //       child: Center(child: Text("Dark")),width: 50,
                //     ),
                //   ],
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsTitle extends StatelessWidget {
  final String? title;

  const SettingsTitle({Key? key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.fromLTRB(6, 8, 6, 8), child: Text(title!));
  }
}
