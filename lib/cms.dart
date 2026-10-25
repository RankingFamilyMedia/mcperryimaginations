import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF0B6B3A))),
        home: CmsGate(service: service),
      );
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
      await widget.service.auth.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.message ?? 'Sign-in failed.');
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
