import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'services.dart';
import 'ui.dart';

class CmsApp extends StatelessWidget {
  const CmsApp({super.key, required this.service});
  final MarketplaceService service;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AutoYaad CMS',
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
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFFCBD5D1))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFFCBD5D1))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFF003C2F), width: 2))),
          cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)))),
        ),
        home: CmsGate(service: service),
      );
}

class PartnerApp extends StatelessWidget {
  const PartnerApp({super.key, required this.service});
  final MarketplaceService service;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AutoYaad Publisher',
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
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFFCBD5D1))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFFCBD5D1))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFF003C2F), width: 2))),
          cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)))),
        ),
        home: PartnerGate(service: service),
      );
}

class PartnerGate extends StatelessWidget {
  const PartnerGate({super.key, required this.service});
  final MarketplaceService service;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
      stream: service.auth.authStateChanges(),
      initialData: service.auth.currentUser,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) return PartnerLogin(service: service);
        return StreamBuilder<AppUser?>(
            stream: service.profile(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.hasError) {
                return _partnerMessage(
                    context,
                    'Could not load your publisher profile. Check your connection and try again.',
                    service.auth.signOut);
              }
              if (!profileSnapshot.hasData) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              final profile = profileSnapshot.data;
              if (profile == null ||
                  !['seller', 'partner'].contains(profile.role)) {
                return _partnerMessage(
                    context,
                    'Publisher access is not enabled for this account. Ask AutoYaad administration to assign the seller or partner role.',
                    service.auth.signOut);
              }
              return PartnerDashboard(service: service, profile: profile);
            });
      });

  Widget _partnerMessage(
          BuildContext context, String message, VoidCallback signOut) =>
      Scaffold(
          appBar: AppBar(title: const Text('AutoYaad Publisher')),
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.storefront_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                        onPressed: signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Back to sign in'))
                  ]))));
}

class PartnerLogin extends StatelessWidget {
  const PartnerLogin({super.key, required this.service});
  final MarketplaceService service;

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(26),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Image.asset('assets/branding/autoyaad_icon.png',
                                width: 78, height: 78),
                            const SizedBox(height: 12),
                            Text('AutoYaad Publisher',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text(
                                'Upload vehicles from anywhere. Every partner listing is sent to AutoYaad for approval before it goes live.',
                                textAlign: TextAlign.center),
                            const SizedBox(height: 22),
                            SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => PartnerSignIn(
                                                service: service))),
                                    icon: const Icon(Icons.login),
                                    label: const Text('Sign in as publisher'))),
                            const SizedBox(height: 8),
                            TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            AuthPage(service: service))),
                                child: const Text('Create a seller account'))
                          ])))))));
}

class PartnerSignIn extends StatefulWidget {
  const PartnerSignIn({super.key, required this.service});
  final MarketplaceService service;
  @override
  State<PartnerSignIn> createState() => _PartnerSignInState();
}

class _PartnerSignInState extends State<PartnerSignIn> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Publisher sign in')),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(
            controller: password,
            obscureText: true,
            onSubmitted: (_) => _signIn(),
            decoration: const InputDecoration(labelText: 'Password')),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: TextStyle(color: Colors.red))
        ],
        const SizedBox(height: 20),
        FilledButton(
            onPressed: busy ? null : _signIn,
            child: Text(busy ? 'Signing in...' : 'Sign in'))
      ]));

  Future<void> _signIn() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.service.auth.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.message ?? 'Sign-in failed.');
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class PartnerDashboard extends StatelessWidget {
  const PartnerDashboard(
      {super.key, required this.service, required this.profile});
  final MarketplaceService service;
  final AppUser profile;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('AutoYaad Publisher'), actions: [
        IconButton(
            tooltip: 'Sign out',
            onPressed: service.auth.signOut,
            icon: const Icon(Icons.logout))
      ]),
      body: StreamBuilder<List<Vehicle>>(
          stream: service.sellerVehicles(profile.uid),
          builder: (context, snap) {
            final listings = snap.data ?? [];
            return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Card(
                      color: const Color(0xFFE5F5EF),
                      child: const ListTile(
                          leading: Icon(Icons.cloud_upload_outlined),
                          title: Text('Publish from anywhere'),
                          subtitle: Text(
                              'Upload up to ten photos. Listings remain pending until AutoYaad approves them.'))),
                  const SizedBox(height: 14),
                  Text('My listings',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (snap.hasError)
                    const Text('Unable to load listings. Please try again.')
                  else if (snap.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (listings.isEmpty)
                    const Card(
                        child: ListTile(
                            leading: Icon(Icons.directions_car_outlined),
                            title: Text('No listings yet'),
                            subtitle: Text(
                                'Tap Post vehicle to upload your first car or bike.')))
                  else
                    ...listings.map((v) => Card(
                        child: ListTile(
                            leading: v.images.isEmpty
                                ? const Icon(Icons.directions_car)
                                : CachedNetworkImage(
                                    imageUrl: v.images.first,
                                    width: 72,
                                    height: 58,
                                    fit: BoxFit.cover),
                            title: Text(v.title),
                            subtitle: Text(
                                '${ghc.format(v.price)} • ${v.status.toUpperCase()}'))))
                ]);
          }),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      VehicleForm(service: service, isAdmin: false))),
          icon: const Icon(Icons.add),
          label: const Text('Post vehicle')));
}

class CmsGate extends StatelessWidget {
  const CmsGate({super.key, required this.service});
  final MarketplaceService service;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: service.auth.authStateChanges(),
        initialData: service.auth.currentUser,
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;
          if (user == null) return CmsLogin(service: service);
          return StreamBuilder<AppUser?>(
              stream: service.profile(user.uid),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.hasError) {
                  final errorText = profileSnapshot.error?.toString() ??
                      'Unknown Firestore error';
                  return Scaffold(
                      appBar: AppBar(title: const Text('AutoYaad CMS')),
                      body: Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.cloud_off_outlined,
                                        size: 52),
                                    const SizedBox(height: 14),
                                    const Text(
                                        'The CMS could not load your admin profile.'),
                                    const SizedBox(height: 8),
                                    const Text(
                                        'Check your internet connection and make sure your Firebase users profile exists.'),
                                    const SizedBox(height: 16),
                                    SelectableText(
                                        'Signed-in email: ${user.email ?? '(not available)'}\n'
                                        'UID: ${user.uid}\n'
                                        'Firebase project: mcperry-market-place'),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                        onPressed: () => Clipboard.setData(
                                            ClipboardData(text: user.uid)),
                                        icon: const Icon(Icons.copy),
                                        label: const Text('Copy UID')),
                                    const SizedBox(height: 8),
                                    Text('Firestore error: $errorText',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    const SizedBox(height: 18),
                                    FilledButton.icon(
                                        onPressed: service.auth.signOut,
                                        icon: const Icon(Icons.logout),
                                        label: const Text('Back to sign in'))
                                  ]))));
                }
                final profile = profileSnapshot.data;
                if (!profileSnapshot.hasData) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }
                if (profile == null || !profile.isAdmin) {
                  return Scaffold(
                      appBar:
                          AppBar(title: const Text('AutoYaad CMS'), actions: [
                        IconButton(
                            tooltip: 'Sign out',
                            onPressed: service.auth.signOut,
                            icon: const Icon(Icons.logout))
                      ]),
                      body: const Center(
                          child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                  'This account is not an administrator. Ask the owner to assign the admin role in Firestore.'))));
                }
                return AdminDashboard(service: service);
              });
        },
      );
}

class CmsLogin extends StatefulWidget {
  const CmsLogin({super.key, required this.service});
  final MarketplaceService service;

  @override
  State<CmsLogin> createState() => _CmsLoginState();
}

class _CmsLoginState extends State<CmsLogin> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.admin_panel_settings_outlined,
                            size: 56),
                        const SizedBox(height: 14),
                        Text('AutoYaad CMS',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        const Text(
                            'Sign in with an administrator account to manage listings, users, offers, reports and sales.'),
                        const SizedBox(height: 22),
                        TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration(labelText: 'Email')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: password,
                            obscureText: true,
                            onSubmitted: (_) => _signIn(),
                            decoration:
                                const InputDecoration(labelText: 'Password')),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: busy ? null : _signIn,
                                child: Text(busy ? 'Signing in…' : 'Sign in')))
                      ]))))));

  Future<void> _signIn() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.service.auth
          .signInWithEmailAndPassword(
              email: email.text.trim(), password: password.text)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException(
                'Sign-in timed out. Check your connection and Firebase setup.'),
          );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.message ?? 'Sign-in failed.');
    } on TimeoutException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
