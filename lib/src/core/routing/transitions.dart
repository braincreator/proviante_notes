import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

Route<T> buildSharedAxisTransitionRoute<T>(Widget page, {SharedAxisTransitionType type = SharedAxisTransitionType.scaled}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: type,
        child: child,
      );
    },
  );
}