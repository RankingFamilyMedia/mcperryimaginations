# AutoYaad Ghana

A Flutter/Firebase managed marketplace for cars, motorbikes and commercial vehicles. Sellers create accounts and submit vehicles; administrators approve listings, can post vehicles directly, manage offers, verification, reservation and completed sales. Managed sales calculate a 10% platform commission.

## Implemented MVP

- Visitor marketplace browsing and search
- Persistent saved vehicles for visitors and signed-in users
- Buyer and seller email registration
- Seller vehicle submission with up to ten images
- Mandatory admin approval for seller listings
- Administrator vehicle posting with immediate approval
- Cars, motorbikes and commercial vehicles
- Vehicle specifications and image gallery
- Featured and verified controls
- Buyer offers routed through administration
- Listing reports
- Seller dashboard and sold-state request
- Admin approve, reject, reserve and confirm-sold actions
- 10% commission and seller-net calculation
- Server-side transaction ledger when admin confirms sold
- Call, WhatsApp and sharing actions
- Firestore and Storage security rules
- Desktop/web CMS mode for administrators
- Sample vehicle seed and removal actions in the CMS
- Demo fallback with one car, bicycle, electric bike, motorbike and commercial vehicle when no approved listings exist
- Native AdMob placement using the configured Android ad unit

## Initial Firebase setup

1. Extract the ZIP and open PowerShell in this folder.
2. Run `powershell -ExecutionPolicy Bypass -File .\setup_windows.ps1`.
3. Install CLIs if needed: `npm install -g firebase-tools` and `dart pub global activate flutterfire_cli`.
4. Run `firebase login` and `firebase use YOUR_PROJECT_ID`.
5. Run `flutterfire configure` and select Android.
6. Enable Email/Password Authentication, Cloud Firestore and Firebase Storage.
7. Run `firebase deploy --only firestore:rules,firestore:indexes,storage`.
8. In `functions`, run `npm install`, return to the root, and run `firebase deploy --only functions`.
9. Run `flutter analyze`, `flutter test`, then `flutter run`.

## Desktop CMS

The CMS is a Flutter web app that can be installed from Chrome or Edge as a desktop PWA. It uses the same Firebase project and administrator roles as the phone app.

```powershell
flutter run -d chrome --dart-define=CMS_MODE=true
flutter build web --release --dart-define=CMS_MODE=true
```

After signing in with an administrator account, the CMS provides listing moderation, users, offers, reports, transactions and sample-vehicle controls. The generated `build\web` folder can be deployed to Firebase Hosting or another HTTPS host.

When the remote marketplace has no approved listings, the phone app displays five clearly marked demo vehicles (car, bicycle, electric bike, motorbike and commercial) so the store preview is usable. The first approved listing created through the CMS automatically replaces this fallback.

The public launch website for this project is `https://rankingfamily.com`. Firebase Hosting still needs to be enabled and the domain connected in Firebase Hosting/DNS before the first public deployment. The Firebase project’s fallback site is normally `https://mcperry-market-place.web.app`.

## AdMob and ads.txt

The Android native ad unit is configured as `ca-app-pub-6208745110537063/4728323231`. Replace the test `ADMOB_APP_ID` value in the Android build configuration with the production AdMob App ID, which is a different value containing `~` rather than `/`.

For a mobile app, AdMob verifies `app-ads.txt` at the root of the developer website. Both `web\app-ads.txt` and `web\ads.txt` are included with the publisher authorization line. After deployment, the verification URL will be `https://rankingfamily.com/app-ads.txt`; it becomes active only after that file is publicly reachable and `rankingfamily.com` is added to the AdMob app settings.

## Photo uploads

The recovered phone build calls the Firebase Function `createR2UploadUrl` for photo uploads. The local Functions source still needs the Cloudflare R2 signing implementation and its private environment configuration before production photo uploads are enabled. Do not put R2 credentials in Flutter or in this repository.

## Build the Android release

After Firebase setup and successful testing, run:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

The Play Store bundle will be created at
`build\app\outputs\bundle\release\app-release.aab`.

## Create the first administrator

Register normally in the app. In Firebase Console > Firestore > `users` > your UID, change `role` from `seller` or `buyer` to `admin` and set `verified` to `true`. Client registration rules prevent users from assigning themselves the admin role.

## Important production work

- Replace the default contact fields with AutoYaad business numbers.
- Add Ghana Card/document verification through a lawful process; never store raw identity documents without a retention and security policy.
- Integrate Flutterwave only through a protected backend. Never put secret keys in Flutter.
- Use a licensed payment/escrow partner before holding full vehicle payments.
- Obtain signed managed-sale agreements covering the 10% commission.
- Configure a permanent Android upload keystore, launcher icons and Play Store materials.
- Add payment webhooks only after your gateway account and transaction rules are finalized.

This ZIP does not contain secret credentials or pretend that payment/identity verification is complete.
