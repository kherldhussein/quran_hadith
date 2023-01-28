import 'package:flutter/material.dart';

class ListItems extends StatelessWidget {
  ListItems({Key? key, this.children}) : super(key: key);
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(padding: const EdgeInsets.all(8), children: children!),
      ),
    );
  }
}

class MItems extends StatelessWidget {
  final String? text;
  final VoidCallback? pressed;

  const MItems({Key? key, this.text, this.pressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return InkWell(
      child: Container(
          alignment: AlignmentDirectional.centerStart,
          constraints: BoxConstraints(minHeight: height / 12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text!)),
      onTap: () => pressed!(),
    );
  }
}
