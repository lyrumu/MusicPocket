import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color lightBgBase = Color(0xFFEEECE6);
  static const Color lightBgDeep = Color(0xFFFBFAF7);
  static const Color lightBgRaised = Color(0xFFFFFFFF);
  static const Color lightFgBase = Color(0xFF25221F);
  static const Color lightFgMute = Color(0xFF777069);
  static const Color lightFgSoft = Color(0xFF9F978D);
  static const Color lightLine = Color(0xFFD8D3CA);
  static const Color lightAccent = Color(0xFF4566D6);
  static const Color lightAccentSoft = Color(0xFFDFE6FF);
  static const Color lightClay = Color(0xFFC66F4E);
  static const Color lightOat = Color(0xFFDFD0B5);

  static const Color darkBgBase = Color(0xFF171614);
  static const Color darkBgDeep = Color(0xFF211F1C);
  static const Color darkBgRaised = Color(0xFF2B2824);
  static const Color darkFgBase = Color(0xFFF3EEE7);
  static const Color darkFgMute = Color(0xFFB9B1A7);
  static const Color darkFgSoft = Color(0xFF8D857B);
  static const Color darkLine = Color(0xFF3B3732);
  static const Color darkAccent = Color(0xFF7892F3);
  static const Color darkAccentSoft = Color(0xFF2D3657);
  static const Color darkClay = Color(0xFFD98968);
  static const Color darkOat = Color(0xFF594E40);

  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkAccent
      : lightAccent;

  static Color clay(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkClay : lightClay;

  static Color oat(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkOat : lightOat;

  static const List<Color> placeholderCovers = [
    Color(0xFF4566D6),
    Color(0xFF5D73C8),
    Color(0xFFC66F4E),
    Color(0xFF9B735F),
    Color(0xFF557C78),
    Color(0xFF7670A5),
  ];

  static Color getPlaceholderColor(String? text) {
    if (text == null || text.isEmpty) return placeholderCovers.first;
    return placeholderCovers[text.hashCode.abs() % placeholderCovers.length];
  }
}
