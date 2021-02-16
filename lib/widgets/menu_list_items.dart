import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ListItems extends StatelessWidget {
  ListItems({Key key, this.children}) : super(key: key);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(padding: const EdgeInsets.all(8), children: children),
      ),
    );
  }
}

class MItems extends StatelessWidget {
  final String text;
  final Function pressed;

  const MItems({Key key, @required this.text, @required this.pressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    double height = MediaQuery.of(context).size.height;
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    return InkWell(
      child: Container(
          alignment: AlignmentDirectional.centerStart,
          constraints: BoxConstraints(minHeight: height / 12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text)),
      onTap: pressed,
    );
  }
}