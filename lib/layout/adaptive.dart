import 'package:adaptive_breakpoints/adaptive_breakpoints.dart';
import 'package:flutter/material.dart';

/// Returns a boolean value whether the window is considered medium or large size.
///
/// Used to build adaptive and responsive layouts.
bool isDisplayDesktop(BuildContext context) =>
    getWindowType(context) >= AdaptiveWindowType.medium;

/// Returns boolean value whether the window is considered medium size.
/// ie Tablets
/// Used to build adaptive and responsive layouts.
bool isDisplaySmallDesktop(BuildContext context) =>
    getWindowType(context) == AdaptiveWindowType.small;

bool isDisplayVerySmallDesktop(BuildContext context) =>
    getWindowType(context) == AdaptiveWindowType.xsmall;
