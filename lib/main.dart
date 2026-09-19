import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'door_splash.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'owner_page.dart';
import 'services/lang.dart';
import 'services/font_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bgDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await Lang.init();
  await TextStyleService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MEGATRON',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: TextStyleService.fontFamily.isNotEmpty ? TextStyleService.fontFamily : 'Inter',
        scaffoldBackgroundColor: AppTheme.bgDeep,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF00FF41),
          secondary: const Color(0xFF00FF41),
          background: AppTheme.bgDeep,
          surface: AppTheme.bgCard,
          onPrimary: AppTheme.bgDeep,
          onSurface: AppTheme.textPrimary,
        ),
        primaryColor: const Color(0xFF00FF41),
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.bgCard,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
          titleTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        cardTheme: CardThemeData(
          color: AppTheme.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            side: const BorderSide(color: AppTheme.borderBold, width: AppTheme.borderW),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppTheme.primaryButton(AppTheme.gold),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.borderBold, width: AppTheme.borderW),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00FF41),
          foregroundColor: AppTheme.bgDeep,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.bgInput,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF00FF41), width: AppTheme.borderW),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.borderBold, width: AppTheme.borderW),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.coral, width: AppTheme.borderW),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.coral, width: AppTheme.borderW),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppTheme.bgCard,
          contentTextStyle: const TextStyle(color: AppTheme.textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            side: const BorderSide(color: AppTheme.borderBold, width: AppTheme.borderW),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            side: const BorderSide(color: AppTheme.borderBold, width: AppTheme.borderW),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
      ),
      home: const CyberSplashPage(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/dashboard':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: args['username'],
                password: args['password'],
                role: args['role'],
                sessionKey: args['key'],
                expiredDate: args['expiredDate'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                listDoos: List<Map<String, dynamic>>.from(args['listDoos'] ?? []),
                news: List<Map<String, dynamic>>.from(args['news'] ?? []),
              ),
            );

          case '/home':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => HomePage(
                username: args['username'],
                password: args['password'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                role: args['role'],
                expiredDate: args['expiredDate'],
                sessionKey: args['sessionKey'],
              ),
            );

          case '/owner':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => OwnerPage(
                sessionKey: args['sessionKey'],
                username: args['username'],
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const CyberSplashPage(),
            );
        }
      },
    );
  }
}
