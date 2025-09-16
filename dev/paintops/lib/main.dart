import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/operations_provider.dart';
import 'repositories/project_repository.dart';
import 'repositories/timesheet_repository.dart';
import 'repositories/expense_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/landing_page.dart';
import 'screens/landing_page_admin_screen.dart';

// Environment configuration
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: kDebugMode ? 'https://jhhsolmxtloxsmlgcexl.supabase.co' : '',
);

const supabaseKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY', 
  defaultValue: kDebugMode ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoaHNvbG14dGxveHNtbGdjZXhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4NTE1NDYsImV4cCI6MjA3MzQyNzU0Nn0.XsBuNPcVP9QvCjdjAn-dHwi_KAilaNbSZmlQbbtwIaM' : '',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Validate environment configuration
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    if (kDebugMode) {
      print('WARNING: Supabase configuration missing. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.');
    }
    // In production, you might want to show an error screen or use fallback configuration
  }
  
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    
    if (kDebugMode) {
      print('Supabase initialized successfully');
      print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Supabase initialization failed: $e');
    }
    // Continue app initialization even if Supabase fails
    // This allows the app to function in offline mode or with fallback data
  }
  
  runApp(const PaintOpsApp());
}

class PaintOpsApp extends StatelessWidget {
  const PaintOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => ProjectRepository()),
        Provider(create: (_) => TimesheetRepository()),
        Provider(create: (_) => ExpenseRepository()),
        ChangeNotifierProxyProvider4<AuthProvider, ProjectRepository, TimesheetRepository, ExpenseRepository, OperationsProvider>(
          create: (context) => OperationsProvider(
            context.read<ProjectRepository>(),
            context.read<TimesheetRepository>(),
            context.read<ExpenseRepository>(),
          ),
          update: (context, auth, projectRepo, timesheetRepo, expenseRepo, previous) =>
              previous ?? OperationsProvider(projectRepo, timesheetRepo, expenseRepo),
        ),
      ],
      child: MaterialApp(
        title: 'PaintOps',
        debugShowCheckedModeBanner: false,
        theme: _buildPremiumTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const LandingPage(),
          '/app': (context) => const AppRouter(),
          '/landing': (context) => const LandingPage(),
          '/landing-admin': (context) => const LandingPageAdminScreen(),
        },
        // Enhanced web configuration
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Ensure proper text scaling on web
              textScaleFactor: kIsWeb ? 1.0 : MediaQuery.of(context).textScaleFactor,
            ),
            child: child!,
          );
        },
      ),
    );
  }

  ThemeData _buildPremiumTheme() {
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w300),
        displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w400),
        displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w500),
        headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF37474F),
        primary: const Color(0xFF37474F),
        secondary: const Color(0xFFB0BEC5),
        tertiary: const Color(0xFF263238),
        surface: const Color(0xFFF8F9FA),
        background: const Color(0xFFFFFFFF),
        onPrimary: Colors.white,
        onSecondary: const Color(0xFF263238),
        onSurface: const Color(0xFF263238),
        onBackground: const Color(0xFF263238),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        elevation: kIsWeb ? 6 : 8,
        shadowColor: Colors.black.withOpacity(kIsWeb ? 0.12 : 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF37474F),
          foregroundColor: Colors.white,
          elevation: kIsWeb ? 4 : 6,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 28 : 24,
            vertical: kIsWeb ? 14 : 12,
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF37474F),
          side: BorderSide(
            color: const Color(0xFF37474F), 
            width: kIsWeb ? 1.5 : 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 28 : 24,
            vertical: kIsWeb ? 14 : 12,
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF37474F), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFF37474F),
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
        elevation: kIsWeb ? 2 : 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
