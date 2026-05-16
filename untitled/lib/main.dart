import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'notes_list_screen.dart';
import 'onboarding_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seen_onboarding')?? false;

  runApp(MyApp(seenOnboarding: seenOnboarding)); // pass it here
}

class MyApp extends StatefulWidget {
  final bool seenOnboarding; // <-- you were missing this line

  const MyApp({super.key, required this.seenOnboarding}); // <-- and this

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() => _isDarkMode =!_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        useMaterial3: true,
        cardColor: Colors.grey[850],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.purple,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        dialogTheme: DialogThemeData(backgroundColor: Colors.grey[850]),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
      )
          : ThemeData.light().copyWith(
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.purple.shade200,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return NotesListScreen(
              toggleTheme: toggleTheme,
              isDarkMode: _isDarkMode,
            );
          }

          // This now works because seenOnboarding exists in MyApp
          if (!widget.seenOnboarding) {
            return const OnboardingScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}