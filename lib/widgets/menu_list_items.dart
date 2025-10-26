import 'package:flutter/material.dart';

class ListItems extends StatelessWidget {
  const ListItems({super.key, this.children});
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(padding: const EdgeInsets.all(8), children: children!),
    );
  }
}

class MItems extends StatelessWidget {
  final VoidCallback? pressed;
  final String? text;

  const MItems({super.key, this.text, this.pressed});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => pressed!(),
      child: Container(
        alignment: AlignmentDirectional.centerStart,
        constraints: BoxConstraints(minHeight: height / 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(text!),
      ),
    );
  }
}
