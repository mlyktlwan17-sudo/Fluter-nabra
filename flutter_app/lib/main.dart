import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check local token state to automate user sessions
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(NabrahApp(isLoggedIn: isLoggedIn));
}

class NabrahApp extends StatelessWidget {
  final bool isLoggedIn;
  const NabrahApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نبرة - Nabrah Voice Clinical Platform',
      debugShowCheckedModeBanner: false,
      
      // Theme matching the luxurious Emerald Green dark identity of Nabrah Web
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF10B981),
        scaffoldBackgroundColor: const Color(0xFF021B15),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF34D399),
          surface: Color(0xFF042D24),
          background: Color(0xFF021B15),
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      ),
      
      // Auto session router
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
