import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class QhNav extends StatefulWidget {
  const QhNav({required this.child}) : assert(child != null);

  final Widget child;

  @override
  _QhNavState createState() => _QhNavState();
}

class _QhNavState extends State<QhNav> {
  @override
  Widget build(BuildContext context) {
    // final isDesktop = isDisplayDesktop(context);
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: (context) {
            return FadeThroughTransitionSwitcher(
              fillColor: Colors.transparent,
              child: widget.child,
            );
          },
          settings: settings,
        );
      },
    );
  }
}


class FadeThroughTransitionSwitcher extends StatelessWidget {
  const FadeThroughTransitionSwitcher({
    required this.fillColor,
    required this.child,
  })  : assert(fillColor != null),
        assert(child != null);

  final Widget child;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      transitionBuilder: (child, animation, secondaryAnimation) {
        return FadeThroughTransition(
          fillColor: fillColor,
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
        );
      },
      child: child,
    );
  }
}