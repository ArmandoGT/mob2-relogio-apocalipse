import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/event_controller.dart';
import 'controllers/score_controller.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseEnabled = false;
  if (AppFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);
      firebaseEnabled = true;
    } catch (e) {
      debugPrint('Erro ao inicializar Firebase: $e');
      firebaseEnabled = false;
    }
  }

  runApp(RelogioApocalipseApp(firebaseEnabled: firebaseEnabled));
}

class RelogioApocalipseApp extends StatelessWidget {
  const RelogioApocalipseApp({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<AuthService>(
          create: (_) => AuthService(firebaseEnabled: firebaseEnabled),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(firebaseEnabled: firebaseEnabled),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) {
            final controller = AuthController(
              authService: context.read<AuthService>(),
            );
            controller.initialize();
            return controller;
          },
        ),
        ChangeNotifierProvider<ScoreController>(
          create: (_) => ScoreController(),
        ),
        ChangeNotifierProxyProvider4<ApiService, FirestoreService, AuthService,
            ScoreController, EventController>(
          create: (context) => EventController(
            apiService: context.read<ApiService>(),
            firestoreService: context.read<FirestoreService>(),
            authService: context.read<AuthService>(),
            scoreController: context.read<ScoreController>(),
          ),
          update: (context, apiService, firestoreService, authService,
              scoreController, previous) {
            return (previous ?? EventController(
              apiService: apiService,
              firestoreService: firestoreService,
              authService: authService,
              scoreController: scoreController,
            ))
                .updateDependencies(
              apiService: apiService,
              firestoreService: firestoreService,
              authService: authService,
              scoreController: scoreController,
            );
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Relógio do Apocalipse',
        theme: _buildTheme(),
        home: const _AppGate(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const background = Color(0xFFF4F7FB);
    const surface = Colors.white;
    const primary = Color(0xFF102A43);
    const accent = Color(0xFF2563EB);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: primary,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD7E2F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD7E2F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEAF2FF),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        if (authController.isAuthenticated) {
          return const HomeView();
        }

        return const LoginView();
      },
    );
  }
}
