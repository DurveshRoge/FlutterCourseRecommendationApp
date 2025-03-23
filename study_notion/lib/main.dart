import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:study_notion/bloc/auth_bloc.dart';
import 'package:study_notion/bloc/course_bloc.dart';
import 'package:study_notion/screens/favorites_screen.dart';
import 'package:study_notion/screens/home_screen.dart';
import 'package:study_notion/screens/login_screen.dart';
import 'package:study_notion/screens/profile_screen.dart';
import 'package:study_notion/screens/recommendations_screen.dart';
import 'package:study_notion/screens/register_screen.dart';
import 'package:study_notion/screens/settings_screen.dart';
import 'package:study_notion/screens/splash_screen.dart';
import 'package:study_notion/screens/dashboard_screen.dart';
import 'package:study_notion/screens/search_screen.dart';
import 'package:study_notion/screens/preferences_screen.dart';
import 'package:study_notion/screens/appearance_settings_screen.dart';
import 'package:study_notion/services/api_service.dart';

// Import theme provider
import 'package:study_notion/providers/theme_provider.dart';
import 'package:study_notion/providers/user_provider.dart';

void main() {
  runApp(const AppWithProviders());
}

class AppWithProviders extends StatelessWidget {
  const AppWithProviders({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        BlocProvider(create: (context) => CourseBloc(apiService)),
        BlocProvider(create: (context) => AuthBloc(apiService: apiService)),
        // Add ThemeProvider
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // Add UserProvider
        ChangeNotifierProvider(create: (context) => UserProvider(apiService)),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Use a default theme while waiting for theme provider to initialize
    final defaultTheme = ThemeData(
      primaryColor: const Color(0xFF3AAFA9),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3AAFA9),
        primary: const Color(0xFF3AAFA9),
      ),
      scaffoldBackgroundColor: Colors.white,
    );

    return MaterialApp(
      title: 'StudyNotion',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.initialized ? themeProvider.getThemeData() : defaultTheme,
      builder: (context, child) {
        // Add global padding to fix the right overflow
        return MediaQuery(
          // Reduce the width of the app slightly to prevent overflow
          data: MediaQuery.of(context).copyWith(
            padding: MediaQuery.of(context).padding.copyWith(
              right: MediaQuery.of(context).padding.right + 26,
            ),
          ),
          child: child!,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) {
          // Check if we have arguments specifying the initial tab
          final args = ModalRoute.of(context)?.settings.arguments;
          int initialTab = 0;
          
          if (args != null && args is int) {
            initialTab = args;
          }
          
          return HomeScreen(initialTab: initialTab);
        },
        '/dashboard': (context) => const DashboardScreen(),
        '/search': (context) => const SearchScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/preferences': (context) {
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            return PreferencesScreen(user: authState.user);
          }
          // Fallback to login if not authenticated
          return const LoginScreen();
        },
        '/appearance': (context) => const AppearanceSettingsScreen(),
        '/recommendations': (context) => const RecommendationsScreen(),
      },
    );
  }
}
