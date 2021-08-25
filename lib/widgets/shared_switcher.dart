import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class SharedAxisTransitionSwitcher extends StatelessWidget {
  const SharedAxisTransitionSwitcher({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      transitionBuilder: (child, animation, secondaryAnimation) {
        return SharedAxisTransition(
          fillColor: Theme.of(context).appBarTheme.color,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
        );
      },
      child: child,
    );
  }
}
