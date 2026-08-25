import 'package:flutter/material.dart';
import 'package:gui/base/icons.dart';

// ---------------------------------------------------------------
// Helper: Parse color from string (supports "null", Colors.*, Color(0x...), #RRGGBB, #AARRGGBB)
// ---------------------------------------------------------------
Color parseColorSafe(String? value) {
  if (value == null || value.trim().isEmpty || value == 'null') {
    return Colors.transparent;
  }

  final input = value.trim();

  // Named Flutter colors
  const colors = <String, Color>{
    'Colors.transparent': Colors.transparent,
    'Colors.pink': Colors.pink,
    'Colors.red': Colors.red,
    'Colors.deepOrange': Colors.deepOrange,
    'Colors.orange': Colors.orange,
    'Colors.amber': Colors.amber,
    'Colors.yellow': Colors.yellow,
    'Colors.lime': Colors.lime,
    'Colors.lightGreen': Colors.lightGreen,
    'Colors.green': Colors.green,
    'Colors.teal': Colors.teal,
    'Colors.cyan': Colors.cyan,
    'Colors.lightBlue': Colors.lightBlue,
    'Colors.blue': Colors.blue,
    'Colors.indigo': Colors.indigo,
    'Colors.purple': Colors.purple,
    'Colors.deepPurple': Colors.deepPurple,
    'Colors.blueGrey': Colors.blueGrey,
    'Colors.brown': Colors.brown,
    'Colors.grey': Colors.grey,
    'Colors.gray': Colors.grey, // alias
    'Colors.black': Colors.black,
    'Colors.white': Colors.white,
  };

  final namedColor = colors[input];
  if (namedColor != null) return namedColor;

  // Color(0xAARRGGBB)
  final colorMatch = RegExp(r'^Color\(0x([0-9a-fA-F]{8})\)$').firstMatch(input);
  if (colorMatch != null) {
    return Color(int.parse(colorMatch.group(1)!, radix: 16));
  }

  // #RRGGBB or #AARRGGBB
  final hex = input.replaceFirst('#', '');
  if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hex)) {
    return Color(int.parse(hex, radix: 16));
  }

  return Colors.transparent;
}


// ---------------------------------------------------------------
// Helper: Parse color from string not safe
// ---------------------------------------------------------------
Color? parseColor(String? value) {
  if (value == null || value.trim().isEmpty || value == 'null') {
    return null;
  }

  final input = value.trim();

  // Named Flutter colors
  const colors = <String, Color>{
    'Colors.transparent': Colors.transparent,
    'Colors.pink': Colors.pink,
    'Colors.red': Colors.red,
    'Colors.deepOrange': Colors.deepOrange,
    'Colors.orange': Colors.orange,
    'Colors.amber': Colors.amber,
    'Colors.yellow': Colors.yellow,
    'Colors.lime': Colors.lime,
    'Colors.lightGreen': Colors.lightGreen,
    'Colors.green': Colors.green,
    'Colors.teal': Colors.teal,
    'Colors.cyan': Colors.cyan,
    'Colors.lightBlue': Colors.lightBlue,
    'Colors.blue': Colors.blue,
    'Colors.indigo': Colors.indigo,
    'Colors.purple': Colors.purple,
    'Colors.deepPurple': Colors.deepPurple,
    'Colors.blueGrey': Colors.blueGrey,
    'Colors.brown': Colors.brown,
    'Colors.grey': Colors.grey,
    'Colors.gray': Colors.grey, // alias
    'Colors.black': Colors.black,
    'Colors.white': Colors.white,
  };

  final namedColor = colors[input];
  if (namedColor != null) return namedColor;

  // Color(0xAARRGGBB)
  final colorMatch = RegExp(r'^Color\(0x([0-9a-fA-F]{8})\)$').firstMatch(input);
  if (colorMatch != null) {
    return Color(int.parse(colorMatch.group(1)!, radix: 16));
  }

  // #RRGGBB or #AARRGGBB
  final hex = input.replaceFirst('#', '');
  if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hex)) {
    return Color(int.parse(hex, radix: 16));
  }

  return Colors.transparent;
}

// ---------------------------------------------------------------
// Helper: Parse TextAlign
// ---------------------------------------------------------------
TextAlign? parseTextAlign(String? value) {
  if (value == null || value == 'null') return null;
  switch (value) {
    case 'left':
      return TextAlign.left;
    case 'right':
      return TextAlign.right;
    case 'center':
      return TextAlign.center;
    case 'justify':
      return TextAlign.justify;
    default:
      return null;
  }
}

// ---------------------------------------------------------------
// Helper: Parse TextOverflow
// ---------------------------------------------------------------
TextOverflow? parseTextOverflow(String? value) {
  if (value == null || value == 'null') return null;
  switch (value) {
    case 'ellipsis':
      return TextOverflow.ellipsis;
    case 'fade':
      return TextOverflow.fade;
    case 'visible':
      return TextOverflow.visible;
    case 'clip':
      return TextOverflow.clip;
    default:
      return null;
  }
}

// ---------------------------------------------------------------
// Helper: Parse FontWeight
// ---------------------------------------------------------------
FontWeight? parseFontWeight(String? value) {
  if (value == null || value == 'null') return null;
  switch (value) {
    case 'FontWeight.w100':
      return FontWeight.w100;
    case 'FontWeight.w200':
      return FontWeight.w200;
    case 'FontWeight.w300':
      return FontWeight.w300;
    case 'FontWeight.w400':
      return FontWeight.w400;
    case 'FontWeight.w500':
      return FontWeight.w500;
    case 'FontWeight.w600':
      return FontWeight.w600;
    case 'FontWeight.w700':
      return FontWeight.w700;
    case 'FontWeight.w800':
      return FontWeight.w800;
    case 'FontWeight.w900':
      return FontWeight.w900;
    default:
      return null;
  }
}

// ---------------------------------------------------------------
// Parse CSS-like EdgeInsets values
// Supports:
// 10
// 10,20
// 10,20,30
// 10,20,30,40
// ---------------------------------------------------------------
EdgeInsets parseEdgeInsets(String? value) {
  if (value == null || value == 'null' || value.isEmpty) {
    return EdgeInsets.zero;
  }

  final values = value
      .split(',')
      .map((e) => double.tryParse(e.trim()) ?? 0)
      .toList();

  switch (values.length) {
    case 1:
      return EdgeInsets.all(values[0]);

    case 2:
      return EdgeInsets.symmetric(
        vertical: values[0],
        horizontal: values[1],
      );

    case 3:
      return EdgeInsets.only(
        top: values[0],
        left: values[1],
        right: values[1],
        bottom: values[2],
      );

    case 4:
      return EdgeInsets.only(
        top: values[0],
        right: values[1],
        bottom: values[2],
        left: values[3],
      );

    default:
      return EdgeInsets.zero;
  }
}

IconData parseIcon(String name) {
  return icons[name] ?? Icons.help_outline;
}


BoxFit? parseFit(String? value) {
  switch (value) {
    case 'BoxFit.fill':
    case 'fill':
      return BoxFit.fill;

    case 'BoxFit.contain':
    case 'contain':
      return BoxFit.contain;

    case 'BoxFit.cover':
    case 'cover':
      return BoxFit.cover;

    case 'BoxFit.fitWidth':
    case 'fitWidth':
      return BoxFit.fitWidth;

    case 'BoxFit.fitHeight':
    case 'fitHeight':
      return BoxFit.fitHeight;

    case 'BoxFit.scaleDown':
    case 'scaleDown':
      return BoxFit.scaleDown;

    case 'BoxFit.none':
    case 'none':
    case null:
      return null;

    default:
      return null;
  }
}