import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextStyleService {
  static String _fontFamily = 'Orbitron';
  static double _fontSize = 14.0;
  static FontWeight _fontWeight = FontWeight.w400;
  static Color _textColor = Colors.white;

  static String get fontFamily => _fontFamily;
  static double get fontSize => _fontSize;
  static FontWeight get fontWeight => _fontWeight;
  static Color get textColor => _textColor;

  static const List<Map<String, dynamic>> fontOptions = [
    {'name': 'Orbitron', 'family': 'Orbitron', 'style': 'Futuristik'},
    {'name': 'Share Tech Mono', 'family': 'ShareTechMono', 'style': 'Monospace'},
    {'name': 'Roboto', 'family': 'Roboto', 'style': 'Klasik'},
    {'name': 'Inter', 'family': 'Inter', 'style': 'Modern'},
    {'name': 'Poppins', 'family': 'Poppins', 'style': 'Clean'},
    {'name': 'Montserrat', 'family': 'Montserrat', 'style': 'Elegant'},
    {'name': 'Raleway', 'family': 'Raleway', 'style': 'Tipis'},
    {'name': 'Courier New', 'family': 'Courier', 'style': 'Terminal'},
    {'name': 'Arial', 'family': 'Arial', 'style': 'Standar'},
    {'name': 'Georgia', 'family': 'Georgia', 'style': 'Serif'},
    {'name': 'Times New Roman', 'family': 'Times', 'style': 'Tradisional'},
    {'name': 'Verdana', 'family': 'Verdana', 'style': 'Lebar'},
    {'name': 'Trebuchet MS', 'family': 'Trebuchet', 'style': 'Sans'},
    {'name': 'Impact', 'family': 'Impact', 'style': 'Tebal'},
    {'name': 'Comic Sans', 'family': 'Comic', 'style': 'Casual'},
    {'name': 'System Default', 'family': '', 'style': 'Default'},
  ];

  static const List<double> fontSizes = [10, 12, 14, 16, 18, 20, 24, 28, 32];
  static const List<FontWeight> fontWeights = [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ];

  static const List<Map<String, dynamic>> colorPresets = [
    {'name': 'White', 'color': Colors.white},
    {'name': 'Red', 'color': Color(0xFFFF1744)},
    {'name': 'Blue', 'color': Color(0xFF448AFF)},
    {'name': 'Green', 'color': Color(0xFF00E676)},
    {'name': 'Purple', 'color': Color(0xFFB388FF)},
    {'name': 'Orange', 'color': Color(0xFFFF9100)},
    {'name': 'Pink', 'color': Color(0xFFFF80AB)},
    {'name': 'Cyan', 'color': Color(0xFF00E5FF)},
    {'name': 'Yellow', 'color': Color(0xFFFFEA00)},
    {'name': 'Teal', 'color': Color(0xFF64FFDA)},
    {'name': 'Amber', 'color': Color(0xFFFFD740)},
    {'name': 'Light Blue', 'color': Color(0xFF82B1FF)},
  ];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _fontFamily = prefs.getString('app_font_family') ?? 'Orbitron';
    _fontSize = prefs.getDouble('app_font_size') ?? 14.0;
    _fontWeight = FontWeight.values[prefs.getInt('app_font_weight') ?? 3];
    final colorValue = prefs.getInt('app_text_color');
    _textColor = colorValue != null ? Color(colorValue) : Colors.white;
  }

  static Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_font_family', family);
  }

  static Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('app_font_size', size);
  }

  static Future<void> setFontWeight(FontWeight weight) async {
    _fontWeight = weight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_font_weight', weight.index);
  }

  static Future<void> setTextColor(Color color) async {
    _textColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_text_color', color.value);
  }

  static Future<void> reset() async {
    _fontFamily = 'Orbitron';
    _fontSize = 14.0;
    _fontWeight = FontWeight.w400;
    _textColor = Colors.white;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_font_family');
    await prefs.remove('app_font_size');
    await prefs.remove('app_font_weight');
    await prefs.remove('app_text_color');
  }

  static TextStyle getStyle({double? size, FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: _fontFamily.isEmpty ? null : _fontFamily,
      fontSize: size ?? _fontSize,
      fontWeight: weight ?? _fontWeight,
      color: color ?? _textColor,
    );
  }
}
