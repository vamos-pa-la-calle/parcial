import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'config/app_router.dart';

late final GoRouter appRouter;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar Google en plataformas nativas
  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }

  // Inicializar Facebook en Chrome
  if (kIsWeb) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: '1152032067684772',
      cookie: true,
      xfbml: true,
      version: 'v18.0',
    );
  }

  // Inicializar las rutas
  appRouter = createAppRouter();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'app_parcial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.pink, useMaterial3: true),
      routerConfig: appRouter,
    );
  }
}
