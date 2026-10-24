import 'package:flutter/material.dart';

class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({required super.builder});

  @override
  Duration get transitionDuration =>
      MediaQuery.disableAnimationsOf(navigator!.context)
      ? Duration.zero
      : const Duration(milliseconds: 200);

  @override
  Duration get reverseTransitionDuration =>
      MediaQuery.disableAnimationsOf(navigator!.context)
      ? Duration.zero
      : const Duration(milliseconds: 160);
}
