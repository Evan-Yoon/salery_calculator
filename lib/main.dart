import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/salary_provider.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SalaryProvider())],
      child: MaterialApp(
        title: 'Shift Salary Calculator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Manrope',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2B8CEE),
            brightness: Brightness.light,
            surface: const Color(0xFFFFFFFF),
          ),
          scaffoldBackgroundColor: const Color(0xFFF6F7F8),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Manrope',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2B8CEE),
            brightness: Brightness.dark,
            surface: const Color(0xFF1C2A38),
          ),
          scaffoldBackgroundColor: const Color(0xFF111A22),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF111A22),
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: const CardThemeData(color: Color(0xFF1C2A38)),
        ),
        themeMode:
            ThemeMode.dark, // Default to dark as per user preference/screens
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
        home: const HomePage(),
      ),
    );
  }
}
