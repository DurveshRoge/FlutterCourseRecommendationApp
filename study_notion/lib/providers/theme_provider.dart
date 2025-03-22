import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _selectedTheme = 'Default';
  double _fontSize = 1.0;
  bool _reduceAnimations = false;
  bool _initialized = false;
  
  bool get isDarkMode => _isDarkMode;
  String get selectedTheme => _selectedTheme;
  double get fontSize => _fontSize;
  bool get reduceAnimations => _reduceAnimations;
  bool get initialized => _initialized;
  
  // Initialize the theme provider
  ThemeProvider() {
    _loadThemeSettings();
  }
  
  // Load theme settings from shared preferences
  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _selectedTheme = prefs.getString('theme') ?? 'Default';
      _fontSize = prefs.getDouble('font_size') ?? 1.0;
      _reduceAnimations = prefs.getBool('reduce_animations') ?? false;
      _initialized = true;
      
      notifyListeners();
    } catch (e) {
      print('Error loading theme settings: $e');
      // Ensure we're initialized even if there's an error
      _initialized = true;
      notifyListeners();
    }
  }
  
  // Update dark mode setting
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', value);
    } catch (e) {
      print('Error saving dark mode setting: $e');
    }
  }
  
  // Update theme setting
  Future<void> setTheme(String theme) async {
    _selectedTheme = theme;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', theme);
    } catch (e) {
      print('Error saving theme setting: $e');
    }
  }
  
  // Update font size setting
  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('font_size', size);
    } catch (e) {
      print('Error saving font size setting: $e');
    }
  }
  
  // Update animations setting
  Future<void> setReduceAnimations(bool value) async {
    _reduceAnimations = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reduce_animations', value);
    } catch (e) {
      print('Error saving animations setting: $e');
    }
  }
  
  // Save all settings at once
  Future<void> saveAllSettings({
    required bool darkMode,
    required String theme,
    required double fontSize,
    required bool reduceAnimations,
  }) async {
    _isDarkMode = darkMode;
    _selectedTheme = theme;
    _fontSize = fontSize;
    _reduceAnimations = reduceAnimations;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', darkMode);
      await prefs.setString('theme', theme);
      await prefs.setDouble('font_size', fontSize);
      await prefs.setBool('reduce_animations', reduceAnimations);
    } catch (e) {
      print('Error saving all theme settings: $e');
    }
  }
  
  // Get the current theme's color
  Color getThemeColor() {
    switch (_selectedTheme) {
      case 'Ocean':
        return Colors.blue[700]!;
      case 'Nature':
        return Colors.green[700]!;
      case 'Midnight':
        return Colors.indigo[800]!;
      case 'Default':
      default:
        return const Color(0xFF3AAFA9);
    }
  }
  
  // Get the app's theme data based on current settings
  ThemeData getThemeData() {
    final baseTheme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    final themeColor = getThemeColor();
    
    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColor,
        primary: themeColor,
        secondary: _isDarkMode ? themeColor.withOpacity(0.7) : _getLighterShade(themeColor),
        background: _isDarkMode ? const Color(0xFF121212) : Colors.white,
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: _isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: _isDarkMode ? const Color(0xFF262626) : const Color(0xFF17252A),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: themeColor, width: 2),
        ),
      ),
      textTheme: _getAdjustedTextTheme(baseTheme.textTheme),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          return states.contains(MaterialState.selected) ? themeColor : null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          return states.contains(MaterialState.selected) ? themeColor.withOpacity(0.5) : null;
        }),
      ),
    );
  }
  
  // Get lighter shade of a color for secondary color
  Color _getLighterShade(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor.withLightness((hslColor.lightness + 0.1).clamp(0.0, 1.0)).toColor();
  }
  
  // Adjust text theme based on font size setting
  TextTheme _getAdjustedTextTheme(TextTheme baseTheme) {
    // Create a safer version of adjusting font size
    TextStyle? _adjustFontSize(TextStyle? style) {
      if (style == null || style.fontSize == null) return style;
      return style.copyWith(fontSize: style.fontSize! * _fontSize);
    }
    
    return baseTheme.copyWith(
      displayLarge: _adjustFontSize(baseTheme.displayLarge),
      displayMedium: _adjustFontSize(baseTheme.displayMedium),
      displaySmall: _adjustFontSize(baseTheme.displaySmall),
      headlineLarge: _adjustFontSize(baseTheme.headlineLarge),
      headlineMedium: _adjustFontSize(baseTheme.headlineMedium),
      headlineSmall: _adjustFontSize(baseTheme.headlineSmall),
      titleLarge: _adjustFontSize(baseTheme.titleLarge),
      titleMedium: _adjustFontSize(baseTheme.titleMedium),
      titleSmall: _adjustFontSize(baseTheme.titleSmall),
      bodyLarge: _adjustFontSize(baseTheme.bodyLarge),
      bodyMedium: _adjustFontSize(baseTheme.bodyMedium),
      bodySmall: _adjustFontSize(baseTheme.bodySmall),
      labelLarge: _adjustFontSize(baseTheme.labelLarge),
      labelMedium: _adjustFontSize(baseTheme.labelMedium),
      labelSmall: _adjustFontSize(baseTheme.labelSmall),
    );
  }
} 