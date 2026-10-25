import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'ads_consent.dart';
import 'cms.dart';
import 'firebase_options.dart';
import 'services.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const cmsMode = bool.fromEnvironment('CMS_MODE', defaultValue: false);
  runApp(const StartupApp(cmsMode: cmsMode));
}

Future<void> initializeFirebase() async {
  const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  if (useEmulators) {
    if (!kIsWeb) {
      throw StateError('Firebase emulator demo mode is currently web-only.');
    }
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID',
        defaultValue: 'demo-autoyaad');
    if (!projectId.startsWith('demo-')) {
      throw StateError('Emulator demo mode requires a demo-* project ID.');
    }
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'demo-api-key',
            appId: '1:1234567890:web:autoyaad-demo',
            messagingSenderId: '1234567890',
            projectId: projectId,
            storageBucket: '$projectId.appspot.com'));
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    FirebaseFunctions.instanceFor(region: 'us-central1')
        .useFunctionsEmulator('127.0.0.1', 5001);
  } else {
    await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 20));
  }
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await AdsConsentService.initialize();
  }
}

class StartupApp extends StatefulWidget {
  const StartupApp(
      {super.key,
      this.initialize = initializeFirebase,
      this.ready,
      this.cmsMode = false});
  final Future<void> Function() initialize;
  final Widget? ready;
  final bool cmsMode;
  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  late final Future<void> initialization = Future.sync(widget.initialize);
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: SetupRequired(error: snapshot.error.toString()));
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return widget.ready ??
                (widget.cmsMode
                    ? CmsApp(service: MarketplaceService())
                    : AutoYaadApp(service: MarketplaceService()));
          }
          return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                  body: Center(
                      child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Opening AutoYaad Ghana...')
                ],
              ))));
        },
      );
}

class AutoYaadApp extends StatelessWidget {
  const AutoYaadApp({super.key, required this.service});
  final MarketplaceService service;
  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AutoYaad Ghana',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6B3A)),
          scaffoldBackgroundColor: const Color(0xFFF5F7F6),
          inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)))),
          cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18))))),
      home: HomeShell(service: service));
}
