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
              debugShowCheckedModeBanner: false, home: BrandSplash());
        },
      );
}

class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF003C2F),
        body: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/branding/autoyaad_splash.png', fit: BoxFit.cover),
          Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                Color(0xCC003C2F),
                Color(0x66003C2F),
                Color(0xEE001B20)
              ]))),
          SafeArea(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
                  child: Column(children: [
                    const Spacer(),
                    Image.asset('assets/branding/autoyaad_icon.png',
                        width: 112, height: 112),
                    const SizedBox(height: 18),
                    RichText(
                        text: const TextSpan(
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1),
                            children: [
                          TextSpan(
                              text: 'Auto',
                              style: TextStyle(color: Colors.white)),
                          TextSpan(
                              text: 'Yaad',
                              style: TextStyle(color: Color(0xFFD4AF37)))
                        ])),
                    const SizedBox(height: 12),
                    const Text('BUY  •  SELL  •  DRIVE  •  TRUST',
                        style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 2.2,
                            fontSize: 11)),
                    const Spacer(),
                    const Text('Your Trusted Automotive Marketplace',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 18),
                    const SizedBox(
                        width: 80,
                        child: LinearProgressIndicator(
                            minHeight: 4,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFD4AF37))))
                  ])))
        ]),
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003C2F))
            .copyWith(
                primary: const Color(0xFF003C2F),
                secondary: const Color(0xFFD4AF37),
                surface: const Color(0xFFF8F9FA)),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF003C2F),
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent),
        inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                borderSide: BorderSide(color: Color(0xFFCBD5D1))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                borderSide: BorderSide(color: Color(0xFFCBD5D1))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                borderSide: BorderSide(color: Color(0xFF003C2F), width: 2))),
        cardTheme: const CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)))),
        navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Color(0xFF003C2F),
            indicatorColor: Color(0xFFD4AF37),
            labelTextStyle: WidgetStatePropertyAll(
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            iconTheme:
                WidgetStatePropertyAll(IconThemeData(color: Colors.white70))),
      ),
      home: HomeShell(service: service));
}
