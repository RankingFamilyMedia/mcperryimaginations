import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_consent.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'services.dart';

final ghc = NumberFormat.currency(locale: 'en_GH', symbol: 'GH\u20B5 ');

const autoGreen = Color(0xFF003C2F);
const autoGold = Color(0xFFD4AF37);

IconData vehicleIcon(String category) {
  switch (category) {
    case 'Bicycle':
      return Icons.pedal_bike;
    case 'Electric bike':
      return Icons.electric_bike;
    case 'Motorbike':
      return Icons.two_wheeler;
    case 'Commercial':
      return Icons.local_shipping_outlined;
    default:
      return Icons.directions_car;
  }
}

class SetupRequired extends StatelessWidget {
  const SetupRequired({super.key, required this.error});
  final String error;
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(children: [
                    const Icon(Icons.directions_car,
                        size: 72, color: Color(0xFF0B6B3A)),
                    const SizedBox(height: 16),
                    Text('AutoYaad Ghana',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text(
                        'Firebase setup is required before the marketplace can connect.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const SelectableText(
                        'Run: flutterfire configure --platforms=android,web\nSelect your Firebase project, then stop and restart the app.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(error,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center)
                  ])))));
}

class PickedPhotoPreview extends StatefulWidget {
  const PickedPhotoPreview({super.key, required this.file});
  final XFile file;
  @override
  State<PickedPhotoPreview> createState() => _PickedPhotoPreviewState();
}

class _PickedPhotoPreviewState extends State<PickedPhotoPreview> {
  late Future<Uint8List> bytes = widget.file.readAsBytes();
  @override
  void didUpdateWidget(covariant PickedPhotoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file != widget.file) bytes = widget.file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 90,
        height: 90,
        child: FutureBuilder<Uint8List>(
            future: bytes,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Icon(Icons.broken_image);
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Image.memory(snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image));
            }),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.service});
  final MarketplaceService service;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      MarketHome(service: widget.service),
      SavedInfo(service: widget.service),
      AccountPage(service: widget.service)
    ];
    return Scaffold(
        body: SafeArea(child: IndexedStack(index: index, children: pages)),
        bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (v) => setState(() => index = v),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Market'),
              NavigationDestination(
                  icon: Icon(Icons.favorite_outline),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Saved'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Account')
            ]));
  }
}

class MarketHome extends StatefulWidget {
  const MarketHome({super.key, required this.service});
  final MarketplaceService service;
  @override
  State<MarketHome> createState() => _MarketHomeState();
}

class _MarketHomeState extends State<MarketHome> {
  String query = '', category = 'All';
  @override
  Widget build(BuildContext context) => StreamBuilder<List<Vehicle>>(
      stream: widget.service.approvedVehicles(),
      builder: (context, snap) {
        final all = snap.data ?? [];
        final items = all
            .where((v) =>
                (category == 'All' || v.category == category) &&
                (query.isEmpty ||
                    '${v.title} ${v.make} ${v.model} ${v.location}'
                        .toLowerCase()
                        .contains(query.toLowerCase())))
            .toList();
        return CustomScrollView(slivers: [
          SliverAppBar(
              floating: true,
              backgroundColor: autoGreen,
              foregroundColor: Colors.white,
              title: Row(children: [
                Image.asset('assets/branding/autoyaad_icon.png',
                    width: 34, height: 34),
                const SizedBox(width: 9),
                const Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Auto',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  TextSpan(
                      text: 'Yaad',
                      style: TextStyle(
                          color: autoGold, fontWeight: FontWeight.w800))
                ]))
              ]),
              actions: [
                IconButton(
                    onPressed: () => showSearch(
                        context: context,
                        delegate: VehicleSearch(widget.service)),
                    icon: const Icon(Icons.search))
              ]),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF003C2F),
                                  Color(0xFF006B52)
                                ]),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                    color: Color(0xFFD4AF37), width: .7)),
                            child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Buy with confidence',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 6),
                                  Text('BUY  •  SELL  •  DRIVE  •  TRUST',
                                      style: TextStyle(
                                          color: Color(0xFFD4AF37),
                                          fontSize: 11,
                                          letterSpacing: 1.6)),
                                  SizedBox(height: 10),
                                  Text(
                                      'Cars, bikes and commercial vehicles reviewed by AutoYaad.',
                                      style: TextStyle(color: Colors.white70))
                                ])),
                        const SizedBox(height: 16),
                        TextField(
                            onChanged: (v) => setState(() => query = v),
                            decoration: const InputDecoration(
                                hintText: 'Search make, model or location',
                                prefixIcon: Icon(Icons.search))),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                                children: [
                              'All',
                              'Car',
                              'Bicycle',
                              'Electric bike',
                              'Motorbike',
                              'Commercial'
                            ]
                                    .map((e) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                            label: Text(e),
                                            selected: category == e,
                                            selectedColor: autoGold,
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(
                                                color: Color(0xFFCBD5D1)),
                                            onSelected: (_) =>
                                                setState(() => category = e))))
                                    .toList())),
                        const SizedBox(height: 18),
                        Row(children: [
                          Text('Featured listings',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                              onPressed: () => setState(() => category = 'All'),
                              child: const Text('See all'))
                        ])
                      ]))),
          const SliverToBoxAdapter(child: AdBanner()),
          if (snap.hasError)
            const SliverFillRemaining(
                child: Center(
                    child: Text(
                        'Unable to load vehicles. Check your connection and try again.')))
          else if (snap.connectionState == ConnectionState.waiting)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (items.isEmpty)
            const SliverFillRemaining(
                child: Center(child: Text('No approved vehicles found.')))
          else
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                        (_, i) => VehicleCard(
                            vehicle: items[i], service: widget.service),
                        childCount: items.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .67)))
        ]);
      });
}

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  NativeAd? ad;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    if (AdsConsentService.canRequestAds &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final unitId = defaultTargetPlatform == TargetPlatform.iOS
          ? const String.fromEnvironment('ADMOB_IOS_NATIVE_ID',
              defaultValue: 'ca-app-pub-3940256099942544/3986624511')
          : const String.fromEnvironment('ADMOB_ANDROID_NATIVE_ID',
              defaultValue: 'ca-app-pub-3940256099942544/2247696110');
      ad = NativeAd(
          adUnitId: unitId,
          request: const AdRequest(),
          nativeTemplateStyle: NativeTemplateStyle(
              templateType: TemplateType.small,
              mainBackgroundColor: Colors.white,
              primaryTextStyle:
                  NativeTemplateTextStyle(textColor: Colors.black87),
              secondaryTextStyle:
                  NativeTemplateTextStyle(textColor: Colors.black54),
              callToActionTextStyle: NativeTemplateTextStyle(
                  textColor: Colors.white, backgroundColor: Color(0xFF0B6B3A))),
          listener: NativeAdListener(onAdLoaded: (_) {
            debugPrint('AdMob native ad loaded.');
            if (mounted) setState(() => loaded = true);
          }, onAdFailedToLoad: (failedAd, error) {
            debugPrint(
                'AdMob native ad failed: ${error.code} ${error.message}');
            failedAd.dispose();
            if (mounted) setState(() => ad = null);
          }))
        ..load();
    }
  }

  @override
  void dispose() {
    ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = ad;
    if (!loaded || banner == null) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.all(8),
        child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 100, maxHeight: 180),
            child: AdWidget(ad: banner)));
  }
}

class VehicleCard extends StatefulWidget {
  const VehicleCard({super.key, required this.vehicle, required this.service});
  final Vehicle vehicle;
  final MarketplaceService service;

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentImage = 0;

  Vehicle get vehicle => widget.vehicle;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startCarousel();
  }

  @override
  void didUpdateWidget(covariant VehicleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle.id != widget.vehicle.id ||
        oldWidget.vehicle.images.length != widget.vehicle.images.length ||
        oldWidget.vehicle.featured != widget.vehicle.featured) {
      _currentImage = 0;
      _pageController.dispose();
      _pageController = PageController();
      _startCarousel();
    }
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    // Cards in the Featured listings section should rotate whenever they have
    // more than one photo. The moderation `featured` flag still controls the
    // badge, but should not disable the visual carousel.
    if (vehicle.images.length < 2) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients || !mounted) return;
      final next = (_currentImage + 1) % vehicle.images.length;
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeInOutCubic);
    });
  }

  void _moveImage(int direction) {
    if (vehicle.images.length < 2 || !_pageController.hasClients) return;
    final next = (_currentImage + direction) % vehicle.images.length;
    final target = next < 0 ? vehicle.images.length - 1 : next;
    _pageController.animateToPage(target,
        duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  VehicleDetail(vehicle: vehicle, service: widget.service))),
      borderRadius: BorderRadius.circular(18),
      child: Card(
          clipBehavior: Clip.antiAlias,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Stack(fit: StackFit.expand, children: [
              vehicle.images.isEmpty
                  ? Container(
                      color: const Color(0xFFE8F0EC),
                      child: Icon(vehicleIcon(vehicle.category),
                          size: 52, color: autoGreen))
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: vehicle.images.length,
                      onPageChanged: (page) {
                        if (mounted) setState(() => _currentImage = page);
                      },
                      itemBuilder: (_, page) => CachedNetworkImage(
                          imageUrl: vehicle.images[page],
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.broken_image))),
              if (vehicle.featured)
                const Positioned(
                    top: 8,
                    left: 8,
                    child: Chip(
                        label: Text('FEATURED'),
                        visualDensity: VisualDensity.compact)),
              if (vehicle.images.length > 1) ...[
                Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: _carouselButton(
                        icon: Icons.chevron_left,
                        onPressed: () => _moveImage(-1))),
                Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: _carouselButton(
                        icon: Icons.chevron_right,
                        onPressed: () => _moveImage(1))),
                Positioned(
                    bottom: 7,
                    left: 0,
                    right: 0,
                    child: Center(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                child: Text(
                                    '${_currentImage + 1}/${vehicle.images.length}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600))))))
              ],
              if (vehicle.verified)
                const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                        radius: 14, child: Icon(Icons.verified, size: 17)))
            ])),
            Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(ghc.format(vehicle.price),
                          style: const TextStyle(
                              color: autoGreen, fontWeight: FontWeight.bold)),
                      Text('${vehicle.year} \u2022 ${vehicle.location}',
                          maxLines: 1,
                          style: Theme.of(context).textTheme.bodySmall)
                    ]))
          ])));

  Widget _carouselButton(
          {required IconData icon, required VoidCallback onPressed}) =>
      Center(
          child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(icon, color: Colors.white, size: 22)))));
}

class VehicleDetail extends StatelessWidget {
  const VehicleDetail(
      {super.key, required this.vehicle, required this.service});
  final Vehicle vehicle;
  final MarketplaceService service;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(vehicle.title), actions: [
        IconButton(
            onPressed: () => SharePlus.instance.share(ShareParams(
                text:
                    '${vehicle.title}\n${ghc.format(vehicle.price)}\n${vehicle.location}\nAutoYaad Ghana')),
            icon: const Icon(Icons.share))
      ]),
      body: ListView(children: [
        SizedBox(
            height: 280,
            child: vehicle.images.isEmpty
                ? const Center(child: Icon(Icons.directions_car, size: 90))
                : PageView(
                    children: vehicle.images
                        .map((u) =>
                            CachedNetworkImage(imageUrl: u, fit: BoxFit.cover))
                        .toList())),
        Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(vehicle.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold))),
                if (vehicle.verified)
                  const Icon(Icons.verified, color: Colors.blue)
              ]),
              Text(ghc.format(vehicle.price),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF0B6B3A),
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SaveVehicleButton(vehicle: vehicle, service: service),
              const SizedBox(height: 10),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                Chip(label: Text('${vehicle.year}')),
                Chip(label: Text(vehicle.transmission)),
                Chip(label: Text(vehicle.fuel)),
                Chip(label: Text('${vehicle.mileage} km')),
                Chip(label: Text(vehicle.condition))
              ]),
              const SizedBox(height: 18),
              Text('Description',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(vehicle.description),
              const SizedBox(height: 18),
              Card(
                  child: ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(vehicle.location),
                      subtitle: const Text(
                          'Exact private address is not displayed.'))),
              if (vehicle.managedSale)
                Card(
                    child: ListTile(
                        leading:
                            const Icon(Icons.admin_panel_settings_outlined),
                        title: const Text('AutoYaad managed sale'),
                        subtitle: const Text(
                            'Offers, inspection and transaction status are coordinated by administration.'))),
              const Card(
                  child: ListTile(
                      leading: Icon(Icons.payments_outlined),
                      title: Text('Pay in person'),
                      subtitle: Text(
                          'Payment is made at delivery or at the vehicle transaction site. AutoYaad does not collect payment in this app.'))),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => _report(context),
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Report'))),
                const SizedBox(width: 10),
                Expanded(
                    child: FilledButton.icon(
                        onPressed: () => _offer(context),
                        icon: const Icon(Icons.local_offer_outlined),
                        label: const Text('Make offer')))
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () =>
                            launchUrl(Uri.parse('tel:${vehicle.phone}')),
                        icon: const Icon(Icons.call),
                        label: const Text('Call contact'))),
                const SizedBox(width: 10),
                Expanded(
                    child: FilledButton.icon(
                        onPressed: () => launchUrl(
                            Uri.parse(
                                'https://wa.me/${vehicle.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}?text=I%20am%20interested%20in%20${Uri.encodeComponent(vehicle.title)}'),
                            mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp')))
              ])
            ]))
      ]));
  Future<void> _offer(BuildContext context) async {
    if (service.auth.currentUser == null) {
      _needLogin(context);
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => _SubmissionDialog(
        title: 'Submit managed offer',
        offer: true,
        submit: (amount, message) =>
            service.makeOffer(vehicle, amount!, message),
      ),
    );
  }

  Future<void> _report(BuildContext context) async {
    if (service.auth.currentUser == null) {
      _needLogin(context);
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => _SubmissionDialog(
        title: 'Report listing',
        submit: (_, message) => service.report(vehicle, message),
      ),
    );
  }
}

class _SubmissionDialog extends StatefulWidget {
  const _SubmissionDialog(
      {required this.title, required this.submit, this.offer = false});
  final String title;
  final bool offer;
  final Future<void> Function(double?, String) submit;
  @override
  State<_SubmissionDialog> createState() => _SubmissionDialogState();
}

class _SubmissionDialogState extends State<_SubmissionDialog> {
  final amount = TextEditingController(), message = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final value = double.tryParse(amount.text.trim());
    final note = message.text.trim();
    if ((widget.offer &&
            (value == null || !value.isFinite || value <= 0 || value > 1e9)) ||
        (!widget.offer && note.isEmpty) ||
        note.length > 2000) {
      setState(() => error = widget.offer
          ? 'Enter a positive amount up to GH\u20B5 1 billion; message limit is 2,000 characters.'
          : 'Enter a reason of 1\u20132,000 characters.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.submit(value, note);
      if (mounted) Navigator.pop(context);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => error = e.message.toString());
    } catch (_) {
      if (mounted) {
        setState(() =>
            error = 'Could not submit. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !busy,
        child: AlertDialog(
          title: Text(widget.title),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (widget.offer) ...[
              TextField(
                  controller: amount,
                  enabled: !busy,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Offer amount (GH\u20B5)')),
              const SizedBox(height: 10),
            ],
            TextField(
                controller: message,
                enabled: !busy,
                maxLength: 2000,
                decoration: InputDecoration(
                    labelText: widget.offer ? 'Message (optional)' : 'Reason')),
            if (error != null)
              Text(error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ])),
          actions: [
            TextButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: busy ? null : submit,
                child: Text(busy ? 'Sending...' : 'Submit')),
          ],
        ),
      );
}

class SaveVehicleButton extends StatelessWidget {
  const SaveVehicleButton(
      {super.key, required this.vehicle, required this.service});
  final Vehicle vehicle;
  final MarketplaceService service;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
      stream: service.auth.authStateChanges(),
      initialData: service.auth.currentUser,
      builder: (context, auth) {
        final user = auth.data;
        if (user == null) {
          return OutlinedButton.icon(
              onPressed: () => _needLogin(context),
              icon: const Icon(Icons.favorite_border),
              label: const Text('Save vehicle'));
        }
        return StreamBuilder<List<String>>(
            stream: service.savedVehicleIds(user.uid),
            builder: (context, saved) {
              final isSaved = saved.data?.contains(vehicle.id) ?? false;
              return OutlinedButton.icon(
                  onPressed: saved.connectionState == ConnectionState.waiting
                      ? null
                      : () async {
                          try {
                            await service.setSaved(
                                user.uid, vehicle.id, !isSaved);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Could not update saved vehicles.')));
                            }
                          }
                        },
                  icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
                  label: Text(isSaved ? 'Saved' : 'Save vehicle'));
            });
      });
}

class SavedInfo extends StatelessWidget {
  const SavedInfo({super.key, this.service});
  final MarketplaceService? service;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Saved vehicles')),
      body: service == null
          ? const Center(child: Text('Sign in to save vehicles.'))
          : StreamBuilder<User?>(
              stream: service!.auth.authStateChanges(),
              initialData: service!.auth.currentUser,
              builder: (context, auth) {
                final user = auth.data;
                if (user == null) {
                  return const Center(
                      child: Text('Sign in to view saved vehicles.'));
                }
                return StreamBuilder<List<String>>(
                    stream: service!.savedVehicleIds(user.uid),
                    builder: (context, saved) {
                      if (saved.hasError) {
                        return const Center(
                            child: Text('Unable to load saved vehicles.'));
                      }
                      if (saved.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return FutureBuilder<List<Vehicle>>(
                          future: service!.getSavedVehicles(saved.data ?? []),
                          builder: (context, vehicles) {
                            if (vehicles.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (vehicles.hasError) {
                              return const Center(
                                  child:
                                      Text('Unable to load saved vehicles.'));
                            }
                            final list = vehicles.data ?? [];
                            if (list.isEmpty) {
                              return const Center(
                                  child: Text('No saved vehicles yet.'));
                            }
                            return ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final vehicle = list[index];
                                  return ListTile(
                                      leading: const Icon(Icons.directions_car),
                                      title: Text(vehicle.title),
                                      subtitle: Text(ghc.format(vehicle.price)),
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => VehicleDetail(
                                                  vehicle: vehicle,
                                                  service: service!))),
                                      trailing: IconButton(
                                          tooltip: 'Remove saved vehicle',
                                          onPressed: () => service!.setSaved(
                                              user.uid, vehicle.id, false),
                                          icon: const Icon(Icons.favorite)));
                                });
                          });
                    });
              }));
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.service});
  final MarketplaceService service;
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
      stream: service.auth.authStateChanges(),
      initialData: service.auth.currentUser,
      builder: (context, snapshot) => _account(context, snapshot.data));

  Widget _account(BuildContext context, User? user) {
    if (user == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Account')),
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            FilledButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AuthPage(service: service))),
                icon: const Icon(Icons.login),
                label: const Text('Sign in or register')),
            const AdsPrivacyOptionsTile()
          ])));
    }
    return StreamBuilder<AppUser?>(
        stream: service.profile(user.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
                child: Text('Unable to load your profile. Please try again.'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Account')),
              body: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'Your account profile is missing. Please contact support.'),
                TextButton(
                    onPressed: service.auth.signOut,
                    child: const Text('Sign out')),
              ])),
            );
          }
          final p = snap.data;
          return Scaffold(
              appBar: AppBar(title: const Text('My account'), actions: [
                IconButton(
                    onPressed: () => service.auth.signOut(),
                    icon: const Icon(Icons.logout))
              ]),
              body: ListView(padding: const EdgeInsets.all(18), children: [
                CircleAvatar(
                    radius: 34,
                    child: Text((p?.name.isNotEmpty ?? false)
                        ? p!.name[0].toUpperCase()
                        : 'U')),
                const SizedBox(height: 10),
                Text(p?.name ?? user.email ?? 'User',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text((p?.role ?? 'buyer').toUpperCase(),
                    textAlign: TextAlign.center),
                const SizedBox(height: 22),
                if (p?.isSeller ?? false)
                  ListTile(
                      leading: const Icon(Icons.garage_outlined),
                      title: const Text('My vehicle listings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SellerDashboard(
                                  service: service, profile: p!)))),
                if (p?.isSeller ?? false)
                  ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Post a vehicle'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => VehicleForm(
                                  service: service, isAdmin: p!.isAdmin)))),
                if (p?.isAdmin ?? false)
                  ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: const Text('Administration dashboard'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AdminDashboard(service: service)))),
                const ListTile(
                    leading: Icon(Icons.security_outlined),
                    title: Text('Verification status'),
                    subtitle: Text(
                        'Seller, ownership and inspection verification are separate administrative checks.')),
                const AdsPrivacyOptionsTile()
              ]));
        });
  }
}

class AdsPrivacyOptionsTile extends StatefulWidget {
  const AdsPrivacyOptionsTile({super.key});
  @override
  State<AdsPrivacyOptionsTile> createState() => _AdsPrivacyOptionsTileState();
}

class _AdsPrivacyOptionsTileState extends State<AdsPrivacyOptionsTile> {
  Future<bool>? requirement;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      requirement = AdsConsentService.privacyOptionsRequired();
    }
  }

  @override
  Widget build(BuildContext context) {
    final privacyRequirement = requirement;
    if (privacyRequirement == null) return const SizedBox.shrink();
    return FutureBuilder<bool>(
        future: privacyRequirement,
        builder: (context, snapshot) {
          if (snapshot.data != true) return const SizedBox.shrink();
          return ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Ad privacy choices'),
              subtitle:
                  const Text('Review or change your advertising consent.'),
              onTap: () async {
                try {
                  await AdsConsentService.showPrivacyOptions();
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Could not open privacy choices.')));
                }
                if (!mounted) return;
                setState(() =>
                    requirement = AdsConsentService.privacyOptionsRequired());
              });
        });
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.service});
  final MarketplaceService service;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      password = TextEditingController();
  bool register = false, busy = false;
  String role = 'buyer';
  @override
  void dispose() {
    for (final controller in [name, email, phone, password]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(register ? 'Create account' : 'Sign in')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (register) ...[
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'Account type'),
              items: const [
                DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                DropdownMenuItem(
                    value: 'seller', child: Text('Vehicle seller/dealer'))
              ],
              onChanged: (v) => setState(() => role = v!)),
          const SizedBox(height: 12)
        ],
        TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 18),
        FilledButton(
            onPressed: busy ? null : _submit,
            child: Text(busy
                ? 'Please wait...'
                : register
                    ? 'Register'
                    : 'Sign in')),
        TextButton(
            onPressed: busy ? null : () => setState(() => register = !register),
            child: Text(register
                ? 'Already registered? Sign in'
                : 'New user? Create account'))
      ]));
  Future<void> _submit() async {
    setState(() => busy = true);
    try {
      if (register) {
        await widget.service.register(
            name: name.text.trim(),
            email: email.text.trim(),
            phone: phone.text.trim(),
            password: password.text,
            role: role);
      } else {
        await widget.service.auth.signInWithEmailAndPassword(
            email: email.text.trim(), password: password.text);
      }
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Authentication failed.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not finish registration. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class VehicleForm extends StatefulWidget {
  const VehicleForm({super.key, required this.service, required this.isAdmin});
  final MarketplaceService service;
  final bool isAdmin;
  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final title = TextEditingController(),
      make = TextEditingController(),
      model = TextEditingController(),
      year = TextEditingController(),
      price = TextEditingController(),
      location = TextEditingController(),
      mileage = TextEditingController(),
      description = TextEditingController(),
      phone = TextEditingController(),
      whatsapp = TextEditingController();
  String category = 'Car',
      transmission = 'Automatic',
      fuel = 'Petrol',
      condition = 'Used';
  final images = <XFile>[];
  bool busy = false;
  String uploadStatus = '';
  SharedPreferences? _draftPrefs;
  Timer? _draftTimer;
  bool _draftReady = false;

  String get _draftPrefix =>
      'autoyaad.cms.vehicle-draft.${widget.service.auth.currentUser?.uid ?? 'unknown'}';

  List<TextEditingController> get _draftControllers => [
        title,
        make,
        model,
        year,
        price,
        location,
        mileage,
        description,
        phone,
        whatsapp
      ];

  @override
  void initState() {
    super.initState();
    for (final controller in _draftControllers) {
      controller.addListener(_queueDraftSave);
    }
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _draftPrefs = prefs;
    final prefix = _draftPrefix;
    final saved = <TextEditingController, String>{
      title: prefs.getString('$prefix.title') ?? '',
      make: prefs.getString('$prefix.make') ?? '',
      model: prefs.getString('$prefix.model') ?? '',
      year: prefs.getString('$prefix.year') ?? '',
      price: prefs.getString('$prefix.price') ?? '',
      location: prefs.getString('$prefix.location') ?? '',
      mileage: prefs.getString('$prefix.mileage') ?? '',
      description: prefs.getString('$prefix.description') ?? '',
      phone: prefs.getString('$prefix.phone') ?? '',
      whatsapp: prefs.getString('$prefix.whatsapp') ?? ''
    };
    for (final entry in saved.entries) {
      if (entry.value.isNotEmpty) entry.key.text = entry.value;
    }
    final savedCategory = prefs.getString('$prefix.category');
    final savedTransmission = prefs.getString('$prefix.transmission');
    final savedFuel = prefs.getString('$prefix.fuel');
    final savedCondition = prefs.getString('$prefix.condition');
    if (['Car', 'Bicycle', 'Electric bike', 'Motorbike', 'Commercial']
        .contains(savedCategory)) {
      category = savedCategory!;
    }
    if (['Automatic', 'Manual'].contains(savedTransmission)) {
      transmission = savedTransmission!;
    }
    if (['Petrol', 'Diesel', 'Electric', 'Hybrid'].contains(savedFuel)) {
      fuel = savedFuel!;
    }
    if (['New', 'Used', 'Imported'].contains(savedCondition)) {
      condition = savedCondition!;
    }
    _draftReady = true;
    setState(() {});
  }

  void _queueDraftSave() {
    if (!_draftReady || _draftPrefs == null) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 400), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final prefs = _draftPrefs;
    if (prefs == null) return;
    final prefix = _draftPrefix;
    await Future.wait([
      prefs.setString('$prefix.title', title.text),
      prefs.setString('$prefix.make', make.text),
      prefs.setString('$prefix.model', model.text),
      prefs.setString('$prefix.year', year.text),
      prefs.setString('$prefix.price', price.text),
      prefs.setString('$prefix.location', location.text),
      prefs.setString('$prefix.mileage', mileage.text),
      prefs.setString('$prefix.description', description.text),
      prefs.setString('$prefix.phone', phone.text),
      prefs.setString('$prefix.whatsapp', whatsapp.text),
      prefs.setString('$prefix.category', category),
      prefs.setString('$prefix.transmission', transmission),
      prefs.setString('$prefix.fuel', fuel),
      prefs.setString('$prefix.condition', condition)
    ]);
  }

  Future<void> _clearDraft() async {
    _draftTimer?.cancel();
    final prefs = _draftPrefs;
    if (prefs == null) return;
    final prefix = _draftPrefix;
    await Future.wait([
      prefs.remove('$prefix.title'),
      prefs.remove('$prefix.make'),
      prefs.remove('$prefix.model'),
      prefs.remove('$prefix.year'),
      prefs.remove('$prefix.price'),
      prefs.remove('$prefix.location'),
      prefs.remove('$prefix.mileage'),
      prefs.remove('$prefix.description'),
      prefs.remove('$prefix.phone'),
      prefs.remove('$prefix.whatsapp'),
      prefs.remove('$prefix.category'),
      prefs.remove('$prefix.transmission'),
      prefs.remove('$prefix.fuel'),
      prefs.remove('$prefix.condition')
    ]);
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    for (final controller in _draftControllers) {
      controller.removeListener(_queueDraftSave);
    }
    for (final controller in [
      title,
      make,
      model,
      year,
      price,
      location,
      mileage,
      description,
      phone,
      whatsapp
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title:
              Text(widget.isAdmin ? 'Admin: post vehicle' : 'Post a vehicle')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        if (!widget.isAdmin)
          const Card(
              child: ListTile(
                  leading: Icon(Icons.hourglass_top),
                  title: Text('Admin approval required'),
                  subtitle: Text(
                      'Your listing remains pending until AutoYaad reviews it.'))),
        TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Vehicle title')),
        if (_draftReady)
          const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Draft saved on this device while you work.')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _drop(
                  'Category',
                  category,
                  [
                    'Car',
                    'Bicycle',
                    'Electric bike',
                    'Motorbike',
                    'Commercial'
                  ],
                  (v) => setState(() => category = v))),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: year,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Year')))
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: make,
                  decoration: const InputDecoration(labelText: 'Make'))),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: model,
                  decoration: const InputDecoration(labelText: 'Model')))
        ]),
        const SizedBox(height: 10),
        TextField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Price (GH\u20B5)',
                helperText: 'Example: 150000 or 150,000')),
        const SizedBox(height: 10),
        TextField(
            controller: location,
            decoration: const InputDecoration(labelText: 'Region and city')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _drop(
                  'Transmission',
                  transmission,
                  ['Automatic', 'Manual'],
                  (v) => setState(() => transmission = v))),
          const SizedBox(width: 10),
          Expanded(
              child: _drop(
                  'Fuel',
                  fuel,
                  ['Petrol', 'Diesel', 'Electric', 'Hybrid'],
                  (v) => setState(() => fuel = v)))
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _drop('Condition', condition, ['New', 'Used', 'Imported'],
                  (v) => setState(() => condition = v))),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: mileage,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Mileage (km)',
                      helperText: 'Example: 120000 or 120,000')))
        ]),
        const SizedBox(height: 10),
        TextField(
            controller: description,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
                labelText: 'Features and description',
                alignLabelWithHint: true)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Listing contact phone'))),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: whatsapp,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'WhatsApp with country code')))
        ]),
        const SizedBox(height: 14),
        OutlinedButton.icon(
            onPressed: busy ? null : _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text('Select photos (${images.length}/10)')),
        if (images.isNotEmpty)
          SizedBox(
              height: 90,
              child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: images
                      .map((x) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PickedPhotoPreview(file: x)))
                      .toList())),
        const SizedBox(height: 14),
        FilledButton.icon(
            onPressed: busy ? null : _save,
            icon: const Icon(Icons.publish),
            label: Text(busy
                ? uploadStatus
                : widget.isAdmin
                    ? 'Publish now'
                    : 'Submit for approval'))
      ]));
  Widget _drop(String label, String value, List<String> options,
          ValueChanged<String> changed) =>
      DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            changed(v!);
            _queueDraftSave();
          });
  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 82);
    if (mounted && picked.isNotEmpty) {
      setState(() {
        images.clear();
        images.addAll(picked.take(10));
      });
    }
  }

  double? _parsePrice(String value) =>
      double.tryParse(value.trim().replaceAll(RegExp(r'[\s,]'), ''));

  int? _parseMileage(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[\s,]'), '');
    return cleaned.isEmpty ? 0 : int.tryParse(cleaned);
  }

  String? _validationError() {
    final titleValue = title.text.trim();
    final p = _parsePrice(price.text);
    final y = int.tryParse(year.text.trim());
    final km = _parseMileage(mileage.text);

    if (titleValue.isEmpty) return 'Enter a vehicle title.';
    if (titleValue.length > 200) {
      return 'Vehicle title must be 200 characters or fewer.';
    }
    if (y == null) return 'Enter a valid vehicle year.';
    if (y < 1900 || y > DateTime.now().year + 1) {
      return 'Enter a year between 1900 and ${DateTime.now().year + 1}.';
    }
    if (p == null || !p.isFinite) {
      return 'Enter a valid price, for example 150000 or 150,000.';
    }
    if (p <= 0) return 'Price must be greater than zero.';
    if (p > 1e9) return 'Price is too large.';
    if (km == null) {
      return 'Enter mileage as a whole number, for example 120000.';
    }
    if (km < 0) return 'Mileage cannot be negative.';
    if (images.isEmpty) return 'Select at least one vehicle photo.';
    return null;
  }

  Future<void> _save() async {
    final validationError = _validationError();
    if (validationError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }
    final p = _parsePrice(price.text)!;
    final y = int.parse(year.text.trim());
    final km = _parseMileage(mileage.text)!;
    setState(() {
      busy = true;
      uploadStatus = images.length == 1
          ? 'Uploading photo...'
          : 'Uploading photo 1 of ${images.length}...';
    });
    try {
      await widget.service.createVehicle({
        'title': title.text.trim(),
        'category': category,
        'make': make.text.trim(),
        'model': model.text.trim(),
        'year': y,
        'price': p,
        'location': location.text.trim(),
        'transmission': transmission,
        'fuel': fuel,
        'condition': condition,
        'mileage': km,
        'description': description.text.trim(),
        'phone': phone.text.trim(),
        'whatsapp': whatsapp.text.trim()
      }, images, admin: widget.isAdmin, onUploadProgress: (current, total) {
        if (mounted) {
          setState(
              () => uploadStatus = 'Uploading photo $current of $total...');
        }
      }, onStatus: (status) {
        if (mounted) setState(() => uploadStatus = status);
      });
      await _clearDraft();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final detail = e is FirebaseException
            ? '${e.code}${e.message == null ? '' : ': ${e.message}'}'
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not publish this listing. $detail')));
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          uploadStatus = '';
        });
      }
    }
  }
}

class SellerDashboard extends StatelessWidget {
  const SellerDashboard(
      {super.key, required this.service, required this.profile});
  final MarketplaceService service;
  final AppUser profile;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('My listings')),
      body: StreamBuilder<List<Vehicle>>(
          stream: service.sellerVehicles(profile.uid),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(
                  child: Text('Unable to load listings. Please try again.'));
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const Center(
                  child: Text('You have not posted any vehicles.'));
            }
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final v = list[i];
                  return Card(
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
                              '${ghc.format(v.price)} \u2022 ${v.status.toUpperCase()}'),
                          trailing: v.status == 'approved'
                              ? TextButton(
                                  onPressed: () => service.report(v,
                                      'Seller requests admin sale confirmation'),
                                  child: const Text('Request sold'))
                              : null));
                });
          }),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      VehicleForm(service: service, isAdmin: profile.isAdmin))),
          icon: const Icon(Icons.add),
          label: const Text('Post vehicle')));
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.service});
  final MarketplaceService service;
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  MarketplaceService get service => widget.service;
  String vehicleQuery = '';
  String vehicleStatus = 'All';

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 6,
      child: Scaffold(
          appBar: AppBar(
              title: const Text('AutoYaad CMS'),
              actions: [
                IconButton(
                    tooltip: 'Add sample vehicles',
                    onPressed: _seedSamples,
                    icon: const Icon(Icons.auto_awesome_outlined)),
                IconButton(
                    tooltip: 'Remove sample vehicles',
                    onPressed: _deleteSamples,
                    icon: const Icon(Icons.delete_sweep_outlined))
              ],
              bottom: const TabBar(isScrollable: true, tabs: [
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
                Tab(icon: Icon(Icons.directions_car), text: 'Vehicles'),
                Tab(icon: Icon(Icons.local_offer_outlined), text: 'Offers'),
                Tab(icon: Icon(Icons.flag_outlined), text: 'Reports'),
                Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Sales'),
                Tab(icon: Icon(Icons.people_outline), text: 'Accounts')
              ])),
          body: TabBarView(children: [
            _overview(),
            _vehicles(),
            _offers(),
            _reports(),
            _sales(),
            _users()
          ]),
          floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          VehicleForm(service: service, isAdmin: true))),
              icon: const Icon(Icons.add),
              label: const Text('Admin post'))));

  Future<void> _seedSamples() async {
    try {
      final count = await service.seedSampleVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count sample vehicles added.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not add samples: $error')));
      }
    }
  }

  Future<void> _deleteSamples() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Remove sample vehicles?'),
                content: const Text(
                    'This removes only records created by the sample button.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Remove'))
                ]));
    if (confirmed != true) return;
    try {
      final count = await service.deleteSampleVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count sample vehicles removed.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not remove samples: $error')));
      }
    }
  }

  Widget _overview() => StreamBuilder<List<Vehicle>>(
      stream: service.adminVehicles(),
      builder: (context, vehicleSnapshot) => StreamBuilder(
          stream: service.adminOffers(),
          builder: (context, offerSnapshot) => StreamBuilder(
              stream: service.adminReports(),
              builder: (context, reportSnapshot) => StreamBuilder(
                  stream: service.adminTransactions(),
                  builder: (context, saleSnapshot) {
                    final snapshots = [
                      vehicleSnapshot,
                      offerSnapshot,
                      reportSnapshot,
                      saleSnapshot
                    ];
                    if (snapshots.any((snapshot) => snapshot.hasError)) {
                      return const Center(
                          child: Text('Unable to load CMS overview.'));
                    }
                    if (snapshots.any((snapshot) => !snapshot.hasData)) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final vehicles = vehicleSnapshot.data!;
                    final pendingVehicles = vehicles
                        .where((vehicle) => vehicle.status == 'pending')
                        .length;
                    final pendingOffers = offerSnapshot.data!.docs
                        .where((offer) => offer.data()['status'] == 'pending')
                        .length;
                    final openReports = reportSnapshot.data!.docs
                        .where((report) => report.data()['status'] == 'open')
                        .length;
                    final sales = saleSnapshot.data!.docs;
                    final commission = sales.fold<double>(0, (sum, sale) {
                      final amount = sale.data()['commission'];
                      return sum + (amount is num ? amount.toDouble() : 0);
                    });
                    return ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text('Operations overview',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 18),
                          Wrap(spacing: 14, runSpacing: 14, children: [
                            _metric('All listings', '${vehicles.length}',
                                Icons.directions_car_outlined),
                            _metric('Awaiting review', '$pendingVehicles',
                                Icons.pending_actions_outlined),
                            _metric('Pending offers', '$pendingOffers',
                                Icons.local_offer_outlined),
                            _metric('Open reports', '$openReports',
                                Icons.flag_outlined),
                            _metric('Recorded commission',
                                ghc.format(commission), Icons.payments_outlined)
                          ]),
                          const SizedBox(height: 20),
                          const Card(
                              child: ListTile(
                                  leading: Icon(Icons.info_outline),
                                  title: Text('Offline settlement policy'),
                                  subtitle: Text(
                                      'Record payment only after it is received in person at delivery or the vehicle transaction site.')))
                        ]);
                  }))));

  Widget _metric(String label, String value, IconData icon) => SizedBox(
      width: 220,
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Icon(icon,
                    size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(label, maxLines: 2)
                    ]))
              ]))));

  Future<void> _updateUser(String uid,
      {String? role, bool? verified, String? accountStatus}) async {
    try {
      await service.updateUser(uid,
          role: role, verified: verified, accountStatus: accountStatus);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not update this account.')));
      }
    }
  }

  Widget _users() => StreamBuilder(
      stream: service.adminUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load accounts.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!.docs;
        if (users.isEmpty) {
          return const Center(child: Text('No accounts found.'));
        }
        return LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            return ListView(
                children: users.map((document) {
              final user = AppUser.fromDoc(document);
              final isCurrentUser = user.uid == service.auth.currentUser?.uid;
              return Card(
                  child: ExpansionTile(
                      title: Text(user.name.isEmpty ? user.email : user.name),
                      subtitle: Text(
                          '${user.email} \u2022 ${user.role} \u2022 ${user.accountStatus}'),
                      children: [
                    ListTile(
                        title: const Text('Role'),
                        trailing: DropdownButton<String>(
                            value: user.role,
                            items: const ['buyer', 'seller', 'partner', 'admin']
                                .map((role) => DropdownMenuItem(
                                    value: role, child: Text(role)))
                                .toList(),
                            onChanged: isCurrentUser
                                ? null
                                : (role) => _updateUser(user.uid, role: role))),
                    SwitchListTile(
                        title: const Text('Verified publisher'),
                        value: user.verified,
                        onChanged: (value) =>
                            _updateUser(user.uid, verified: value)),
                    SwitchListTile(
                        title: const Text('Account active'),
                        value: user.accountStatus == 'active',
                        onChanged: isCurrentUser
                            ? null
                            : (active) => _updateUser(user.uid,
                                accountStatus: active ? 'active' : 'suspended'))
                  ]));
            }).toList());
          }
          return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Account')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Verified')),
                    DataColumn(label: Text('Status'))
                  ],
                  rows: users.map((document) {
                    final user = AppUser.fromDoc(document);
                    final isCurrentUser =
                        user.uid == service.auth.currentUser?.uid;
                    return DataRow(cells: [
                      DataCell(Text(user.name)),
                      DataCell(Text(user.email)),
                      DataCell(DropdownButton<String>(
                          value: user.role,
                          items: const ['buyer', 'seller', 'partner', 'admin']
                              .map((role) => DropdownMenuItem(
                                  value: role, child: Text(role)))
                              .toList(),
                          onChanged: isCurrentUser
                              ? null
                              : (role) => _updateUser(user.uid, role: role))),
                      DataCell(Checkbox(
                          value: user.verified,
                          onChanged: (value) =>
                              _updateUser(user.uid, verified: value ?? false))),
                      DataCell(Switch(
                          value: user.accountStatus == 'active',
                          onChanged: isCurrentUser
                              ? null
                              : (active) => _updateUser(user.uid,
                                  accountStatus:
                                      active ? 'active' : 'suspended')))
                    ]);
                  }).toList()));
        });
      });

  Widget _vehicles() => StreamBuilder<List<Vehicle>>(
      stream: service.adminVehicles(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
              child: Text('Unable to load listings. Please try again.'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = (snap.data ?? []).where((vehicle) {
          final matchesStatus =
              vehicleStatus == 'All' || vehicle.status == vehicleStatus;
          final text =
              '${vehicle.title} ${vehicle.make} ${vehicle.model} ${vehicle.location}'
                  .toLowerCase();
          return matchesStatus && text.contains(vehicleQuery.toLowerCase());
        }).toList();
        return Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Wrap(spacing: 12, runSpacing: 10, children: [
                SizedBox(
                    width: 360,
                    child: TextField(
                        onChanged: (value) =>
                            setState(() => vehicleQuery = value.trim()),
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'Search all listings'))),
                SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                        initialValue: vehicleStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          'All',
                          'pending',
                          'approved',
                          'reserved',
                          'rejected',
                          'sold'
                        ]
                            .map((status) => DropdownMenuItem(
                                value: status, child: Text(status)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => vehicleStatus = value!)))
              ])),
          Expanded(
              child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(
                color: const Color(0xFFE7F1EE),
                child: ListTile(
                    leading: const Icon(Icons.publish_outlined),
                    title: const Text('Publishing workflow'),
                    subtitle: const Text(
                        'Use Admin post to publish a car immediately. When it sells, open the listing and choose Mark sold to record the agreed price and handoff location.'))),
            const SizedBox(height: 12),
            Card(
                color: const Color(0xFFE8F5E9),
                child: ListTile(
                    leading: const Icon(Icons.percent),
                    title: const Text('Managed-sale commission'),
                    subtitle:
                        const Text('10% of confirmed vehicle sale price'))),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No matching listings.'))),
            ...list.map((v) => Card(
                    child: ExpansionTile(
                        title: Text(v.title),
                        subtitle: Text(
                            '${ghc.format(v.price)} \u2022 ${v.status.toUpperCase()}\nCommission: ${ghc.format(v.commission)} \u2022 Seller net: ${ghc.format(v.sellerNet)}'),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        children: [
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        if (v.status == 'pending' || v.status == 'rejected')
                          FilledButton.tonal(
                              onPressed: () =>
                                  service.updateStatus(v.id, 'approved'),
                              child: const Text('Approve')),
                        if (v.status != 'rejected' && v.status != 'sold')
                          OutlinedButton(
                              onPressed: () =>
                                  service.updateStatus(v.id, 'rejected'),
                              child: const Text('Reject')),
                        if (v.status == 'approved')
                          OutlinedButton(
                              onPressed: () =>
                                  service.updateStatus(v.id, 'reserved'),
                              child: const Text('Reserve')),
                        if (v.status == 'approved' || v.status == 'reserved')
                          FilledButton(
                              onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => OfflineSaleDialog(
                                      service: service, vehicle: v)),
                              child: const Text('Mark sold')),
                        FilterChip(
                            label: const Text('Featured'),
                            selected: v.featured,
                            onSelected: (x) =>
                                service.updateFlags(v.id, featured: x)),
                        FilterChip(
                            label: const Text('Verified'),
                            selected: v.verified,
                            onSelected: (x) =>
                                service.updateFlags(v.id, verified: x))
                      ])
                    ])))
          ])),
        ]);
      });

  Widget _offers() => StreamBuilder(
      stream: service.adminOffers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load offers.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final offers = snapshot.data!.docs;
        if (offers.isEmpty) return const Center(child: Text('No offers yet.'));
        return ListView(
            children: offers.map((offer) {
          final data = offer.data();
          return Card(
              child: ListTile(
                  title: Text(data['vehicleTitle'] ?? 'Vehicle offer'),
                  subtitle: Text(
                      '${ghc.format((data['amount'] as num? ?? 0).toDouble())} \u2022 ${data['status'] ?? 'pending'}\n${data['note'] ?? ''}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                      tooltip: 'Review offer',
                      onSelected: (value) =>
                          service.reviewOffer(offer.id, value),
                      itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'accepted', child: Text('Accept')),
                            PopupMenuItem(
                                value: 'rejected', child: Text('Reject'))
                          ])));
        }).toList());
      });

  Widget _reports() => StreamBuilder(
      stream: service.adminReports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load reports.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data!.docs;
        if (reports.isEmpty) {
          return const Center(child: Text('No listing reports.'));
        }
        return ListView(
            children: reports.map((report) {
          final data = report.data();
          return Card(
              child: ListTile(
                  title: Text(data['vehicleTitle'] ?? 'Listing report'),
                  subtitle: Text(
                      '${data['status'] ?? 'open'} \u2022 ${data['reason'] ?? ''}'),
                  trailing: IconButton(
                      tooltip: 'Close report',
                      onPressed: () =>
                          service.reviewReport(report.id, 'closed'),
                      icon: const Icon(Icons.check_circle_outline))));
        }).toList());
      });

  Widget _sales() => StreamBuilder(
      stream: service.adminTransactions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load sales.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sales = snapshot.data!.docs;
        if (sales.isEmpty) {
          return const Center(child: Text('No completed sales yet.'));
        }
        return ListView(
            children: sales.map((sale) {
          final data = sale.data();
          final location = data['settlementLocation'] == 'delivery'
              ? 'Delivery'
              : 'Transaction site';
          final ownership = data['ownershipTransferStatus'] ?? 'pending';
          return Card(
              child: ListTile(
                  title: Text(data['vehicleTitle'] ?? 'Vehicle sale'),
                  subtitle: Text(
                      '${ghc.format((data['salePrice'] as num? ?? 0).toDouble())} \u2022 ${ghc.format((data['commission'] as num? ?? 0).toDouble())} commission\nPaid in person \u2022 $location \u2022 Ownership $ownership'),
                  isThreeLine: true,
                  trailing: ownership == 'completed'
                      ? const Icon(Icons.verified_outlined)
                      : IconButton(
                          tooltip: 'Mark ownership transferred',
                          onPressed: () =>
                              service.markOwnershipTransferred(sale.id),
                          icon: const Icon(
                              Icons.assignment_turned_in_outlined))));
        }).toList());
      });
}

class OfflineSaleDialog extends StatefulWidget {
  const OfflineSaleDialog(
      {super.key, required this.service, required this.vehicle});
  final MarketplaceService service;
  final Vehicle vehicle;
  @override
  State<OfflineSaleDialog> createState() => _OfflineSaleDialogState();
}

class _OfflineSaleDialogState extends State<OfflineSaleDialog> {
  late final price =
      TextEditingController(text: widget.vehicle.price.toString());
  String location = 'delivery';
  bool busy = false;
  String? error;

  @override
  void dispose() {
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Confirm in-person sale'),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
                'Record the agreed price after payment is received in person. No payment is collected in the app.'),
            const SizedBox(height: 12),
            TextField(
                controller: price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Agreed price (GH\u20B5)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                initialValue: location,
                decoration:
                    const InputDecoration(labelText: 'Handoff location'),
                items: const [
                  DropdownMenuItem(
                      value: 'delivery', child: Text('At delivery')),
                  DropdownMenuItem(
                      value: 'transaction_site',
                      child: Text('Vehicle transaction site'))
                ],
                onChanged:
                    busy ? null : (value) => setState(() => location = value!)),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error))
            ]
          ])),
          actions: [
            TextButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: busy ? null : _confirm,
                child: Text(busy ? 'Saving...' : 'Confirm sale'))
          ]);

  Future<void> _confirm() async {
    final amount = double.tryParse(price.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0 || amount > 1e9) {
      setState(() => error = 'Enter a valid agreed sale price.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.service.confirmOfflineSale(widget.vehicle.id,
          salePrice: amount, settlementLocation: location);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => error = 'Could not record this sale.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class VehicleSearch extends SearchDelegate<Vehicle?> {
  VehicleSearch(this.service);
  final MarketplaceService service;
  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back));
  @override
  Widget buildResults(BuildContext context) => _results();
  @override
  Widget buildSuggestions(BuildContext context) => _results();
  Widget _results() => StreamBuilder<List<Vehicle>>(
      stream: service.approvedVehicles(),
      builder: (context, snap) {
        final list = (snap.data ?? [])
            .where((v) => '${v.title} ${v.make} ${v.model} ${v.location}'
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
        return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => ListTile(
                title: Text(list[i].title),
                subtitle: Text(
                    '${ghc.format(list[i].price)} \u2022 ${list[i].location}'),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => VehicleDetail(
                            vehicle: list[i], service: service)))));
      });
}

void _needLogin(BuildContext context) =>
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please create an account or sign in first.')));
