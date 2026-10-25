import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'models.dart';

final demoVehicles = [
  Vehicle(
      id: 'demo-toyota-corolla',
      sellerId: 'demo',
      title: '2021 Toyota Corolla LE',
      category: 'Car',
      make: 'Toyota',
      model: 'Corolla LE',
      year: 2021,
      price: 185000,
      location: 'Accra, Greater Accra',
      transmission: 'Automatic',
      fuel: 'Petrol',
      condition: 'Used',
      mileage: 54000,
      description:
          'Demo listing: clean family saloon with service history and working air conditioning.',
      phone: '+233 20 000 0000',
      whatsapp: '+233 20 000 0000',
      images: [],
      status: 'approved',
      featured: true,
      verified: true,
      managedSale: true,
      createdAt: DateTime(2025, 1, 1)),
  Vehicle(
      id: 'demo-giant-escape',
      sellerId: 'demo',
      title: '2023 Giant Escape 3 Bicycle',
      category: 'Bicycle',
      make: 'Giant',
      model: 'Escape 3',
      year: 2023,
      price: 8500,
      location: 'Accra, Greater Accra',
      transmission: 'Single-speed',
      fuel: 'Human-powered',
      condition: 'New',
      mileage: 0,
      description:
          'Demo listing: lightweight city bicycle for commuting and leisure rides.',
      phone: '+233 20 000 0000',
      whatsapp: '+233 20 000 0000',
      images: [],
      status: 'approved',
      featured: false,
      verified: true,
      managedSale: true,
      createdAt: DateTime(2025, 1, 1, 1)),
  Vehicle(
      id: 'demo-fiido-electric-bike',
      sellerId: 'demo',
      title: '2023 Fiido M1 Pro Electric Bike',
      category: 'Electric bike',
      make: 'Fiido',
      model: 'M1 Pro',
      year: 2023,
      price: 18500,
      location: 'Kumasi, Ashanti',
      transmission: 'Automatic assist',
      fuel: 'Electric',
      condition: 'New',
      mileage: 120,
      description:
          'Demo listing: foldable electric bike with rechargeable battery assist.',
      phone: '+233 24 000 0000',
      whatsapp: '+233 24 000 0000',
      images: [],
      status: 'approved',
      featured: false,
      verified: true,
      managedSale: true,
      createdAt: DateTime(2025, 1, 1, 2)),
  Vehicle(
      id: 'demo-yamaha-mt07',
      sellerId: 'demo',
      title: '2022 Yamaha MT-07',
      category: 'Motorbike',
      make: 'Yamaha',
      model: 'MT-07',
      year: 2022,
      price: 92000,
      location: 'Kumasi, Ashanti',
      transmission: 'Manual',
      fuel: 'Petrol',
      condition: 'Used',
      mileage: 12000,
      description:
          'Demo listing: agile commuter bike with recent service and clean papers.',
      phone: '+233 24 000 0000',
      whatsapp: '+233 24 000 0000',
      images: [],
      status: 'approved',
      featured: false,
      verified: true,
      managedSale: true,
      createdAt: DateTime(2025, 1, 2)),
  Vehicle(
      id: 'demo-mercedes-sprinter',
      sellerId: 'demo',
      title: '2019 Mercedes-Benz Sprinter',
      category: 'Commercial',
      make: 'Mercedes-Benz',
      model: 'Sprinter',
      year: 2019,
      price: 410000,
      location: 'Tema, Greater Accra',
      transmission: 'Automatic',
      fuel: 'Diesel',
      condition: 'Used',
      mileage: 98000,
      description:
          'Demo listing: dependable commercial van for logistics and passenger service.',
      phone: '+233 27 000 0000',
      whatsapp: '+233 27 000 0000',
      images: [],
      status: 'approved',
      featured: false,
      verified: true,
      managedSale: true,
      createdAt: DateTime(2025, 1, 3))
];

class MarketplaceService {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  Stream<List<Vehicle>> approvedVehicles() async* {
    try {
      await for (final snapshot in db
          .collection('vehicles')
          .where('status', isEqualTo: 'approved')
          .snapshots()) {
        final list = snapshot.docs.map(Vehicle.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield list.isEmpty ? demoVehicles : list;
      }
    } catch (_) {
      yield demoVehicles;
    }
  }

  Stream<List<Vehicle>> adminVehicles() => db
      .collection('vehicles')
      .where('status',
          whereIn: ['pending', 'approved', 'reserved', 'rejected', 'sold'])
      .snapshots()
      .map((s) {
        final list = s.docs.map(Vehicle.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
  Stream<QuerySnapshot<Map<String, dynamic>>> adminUsers() => db
      .collection('users')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> adminOffers() => db
      .collection('offers')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> adminReports() => db
      .collection('reports')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> adminTransactions() => db
      .collection('transactions')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots();
  Stream<List<Vehicle>> sellerVehicles(String uid) => db
      .collection('vehicles')
      .where('sellerId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map(Vehicle.fromDoc).toList());
  Stream<AppUser?> profile(String uid) => db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);
  Stream<List<String>> savedVehicleIds(String uid) => db
      .collection('users')
      .doc(uid)
      .collection('savedVehicles')
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toList());
  Future<void> setSaved(String uid, String vehicleId, bool saved) async {
    final ref = db
        .collection('users')
        .doc(uid)
        .collection('savedVehicles')
        .doc(vehicleId);
    if (saved) {
      await ref.set(
          {'vehicleId': vehicleId, 'savedAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  Future<List<Vehicle>> getSavedVehicles(List<String> ids) async {
    if (ids.isEmpty) return [];
    final vehicles = <Vehicle>[];
    for (var start = 0; start < ids.length; start += 30) {
      final batch = ids.skip(start).take(30).toList();
      final snapshot = await db
          .collection('vehicles')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      vehicles.addAll(snapshot.docs
          .map(Vehicle.fromDoc)
          .where((vehicle) => vehicle.status == 'approved'));
    }
    vehicles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return vehicles;
  }

  Future<int> seedSampleVehicles() async {
    if (auth.currentUser == null) {
      throw StateError('Sign in as an administrator first.');
    }
    const samples = [
      {
        'title': '2021 Toyota Corolla LE',
        'category': 'Car',
        'make': 'Toyota',
        'model': 'Corolla LE',
        'year': 2021,
        'price': 185000.0,
        'location': 'Accra, Greater Accra',
        'transmission': 'Automatic',
        'fuel': 'Petrol',
        'condition': 'Used',
        'mileage': 54000,
        'description':
            'Clean family saloon with service history and working air conditioning.',
        'phone': '+233 20 000 0000',
        'whatsapp': '+233 20 000 0000'
      },
      {
        'title': '2020 Honda CR-V AWD',
        'category': 'Car',
        'make': 'Honda',
        'model': 'CR-V AWD',
        'year': 2020,
        'price': 265000.0,
        'location': 'Kumasi, Ashanti',
        'transmission': 'Automatic',
        'fuel': 'Petrol',
        'condition': 'Imported',
        'mileage': 68000,
        'description': 'Spacious SUV suitable for family and business use.',
        'phone': '+233 24 000 0000',
        'whatsapp': '+233 24 000 0000'
      },
      {
        'title': '2023 Giant Escape 3 Bicycle',
        'category': 'Bicycle',
        'make': 'Giant',
        'model': 'Escape 3',
        'year': 2023,
        'price': 8500.0,
        'location': 'Accra, Greater Accra',
        'transmission': 'Single-speed',
        'fuel': 'Human-powered',
        'condition': 'New',
        'mileage': 0,
        'description':
            'Lightweight city bicycle for commuting and leisure rides.',
        'phone': '+233 20 000 0000',
        'whatsapp': '+233 20 000 0000'
      },
      {
        'title': '2023 Fiido M1 Pro Electric Bike',
        'category': 'Electric bike',
        'make': 'Fiido',
        'model': 'M1 Pro',
        'year': 2023,
        'price': 18500.0,
        'location': 'Kumasi, Ashanti',
        'transmission': 'Automatic assist',
        'fuel': 'Electric',
        'condition': 'New',
        'mileage': 120,
        'description':
            'Foldable electric bike with rechargeable battery assist.',
        'phone': '+233 24 000 0000',
        'whatsapp': '+233 24 000 0000'
      },
      {
        'title': '2022 Yamaha MT-07',
        'category': 'Motorbike',
        'make': 'Yamaha',
        'model': 'MT-07',
        'year': 2022,
        'price': 92000.0,
        'location': 'Tema, Greater Accra',
        'transmission': 'Manual',
        'fuel': 'Petrol',
        'condition': 'Used',
        'mileage': 12000,
        'description':
            'Lightly used motorcycle with fresh tyres and service records.',
        'phone': '+233 50 000 0000',
        'whatsapp': '+233 50 000 0000'
      },
      {
        'title': '2019 Mercedes-Benz Sprinter',
        'category': 'Commercial',
        'make': 'Mercedes-Benz',
        'model': 'Sprinter',
        'year': 2019,
        'price': 410000.0,
        'location': 'Takoradi, Western',
        'transmission': 'Manual',
        'fuel': 'Diesel',
        'condition': 'Used',
        'mileage': 142000,
        'description': 'Commercial van with a practical cargo configuration.',
        'phone': '+233 27 000 0000',
        'whatsapp': '+233 27 000 0000'
      }
    ];
    final batch = db.batch();
    for (final sample in samples) {
      final ref = db.collection('vehicles').doc();
      batch.set(ref, {
        ...sample,
        'sellerId': auth.currentUser!.uid,
        'images': <String>[],
        'status': 'approved',
        'featured': false,
        'verified': true,
        'managedSale': true,
        'isSample': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp()
      });
    }
    await batch.commit();
    return samples.length;
  }

  Future<int> deleteSampleVehicles() async {
    final snapshot = await db
        .collection('vehicles')
        .where('isSample', isEqualTo: true)
        .get();
    if (snapshot.docs.isEmpty) return 0;
    final batch = db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  Future<AppUser?> getProfile(String uid) async {
    final d = await db.collection('users').doc(uid).get();
    return d.exists ? AppUser.fromDoc(d) : null;
  }

  Future<void> register(
      {required String name,
      required String email,
      required String phone,
      required String password,
      required String role}) async {
    final c = await auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await db.collection('users').doc(c.user!.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'verified': false,
      'accountStatus': 'active',
      'createdAt': FieldValue.serverTimestamp()
    });
  }

  Future<void> updateUser(String uid,
      {String? role, bool? verified, String? accountStatus}) async {
    if (role != null && !['buyer', 'seller', 'admin'].contains(role)) {
      throw ArgumentError('Choose a valid account role.');
    }
    if (accountStatus != null &&
        !['active', 'suspended'].contains(accountStatus)) {
      throw ArgumentError('Choose a valid account status.');
    }
    await db.collection('users').doc(uid).update({
      if (role != null) 'role': role,
      if (verified != null) 'verified': verified,
      if (accountStatus != null) 'accountStatus': accountStatus,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  Future<List<String>> uploadImages(List<XFile> files, String owner) async {
    final urls = <String>[];
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (bytes.length >= 8 * 1024 * 1024) {
        throw ArgumentError('Each photo must be smaller than 8 MB.');
      }
      final contentType = file.mimeType ?? 'image/jpeg';
      final signedUpload = await functions
          .httpsCallable('createR2UploadUrl')
          .call<Map<String, dynamic>>({
        'contentType': contentType,
        'sizeBytes': bytes.length,
      });
      final uploadUrl = Uri.parse(signedUpload.data['uploadUrl'] as String);
      final response = await http.put(
        uploadUrl,
        headers: {'Content-Type': contentType},
        body: bytes,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Photo upload failed (${response.statusCode}).');
      }
      urls.add(signedUpload.data['publicUrl'] as String);
    }
    return urls;
  }

  Future<void> createVehicle(Map<String, dynamic> data, List<XFile> images,
      {required bool admin}) async {
    final uid = auth.currentUser!.uid;
    final urls = await uploadImages(images, uid);
    await db.collection('vehicles').add({
      ...data,
      'sellerId': uid,
      'images': urls,
      'status': admin ? 'approved' : 'pending',
      'featured': false,
      'verified': admin,
      'managedSale': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  Future<void> updateStatus(String id, String status) => db
      .collection('vehicles')
      .doc(id)
      .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> updateFlags(String id, {bool? featured, bool? verified}) =>
      db.collection('vehicles').doc(id).update({
        if (featured != null) 'featured': featured,
        if (verified != null) 'verified': verified,
        'updatedAt': FieldValue.serverTimestamp()
      });
  Future<void> confirmOfflineSale(String id,
      {required double salePrice, required String settlementLocation}) async {
    if (!salePrice.isFinite || salePrice <= 0 || salePrice > 1e9) {
      throw ArgumentError('Enter a valid agreed sale price.');
    }
    if (!['delivery', 'transaction_site'].contains(settlementLocation)) {
      throw ArgumentError('Choose delivery or the vehicle transaction site.');
    }
    await db.collection('vehicles').doc(id).update({
      'status': 'sold',
      'salePrice': salePrice,
      'paymentMode': 'offline',
      'paymentStatus': 'received_in_person',
      'settlementLocation': settlementLocation,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  Future<void> reviewOffer(String id, String status) => db
      .collection('offers')
      .doc(id)
      .update({'status': status, 'reviewedAt': FieldValue.serverTimestamp()});
  Future<void> reviewReport(String id, String status) => db
      .collection('reports')
      .doc(id)
      .update({'status': status, 'reviewedAt': FieldValue.serverTimestamp()});
  Future<void> markOwnershipTransferred(String id) =>
      db.collection('transactions').doc(id).update({
        'ownershipTransferStatus': 'completed',
        'ownershipTransferredAt': FieldValue.serverTimestamp()
      });

  Future<void> makeOffer(Vehicle v, double amount, String note) async {
    if (!amount.isFinite || amount <= 0 || amount > 1e9 || note.length > 2000) {
      throw ArgumentError(
          'Enter a positive offer up to GH\u20B5 1 billion and a message under 2,000 characters.');
    }
    final u = auth.currentUser!;
    if (u.uid == v.sellerId) {
      throw ArgumentError('You cannot make an offer on your own listing.');
    }
    await db.collection('offers').add({
      'vehicleId': v.id,
      'vehicleTitle': v.title,
      'sellerId': v.sellerId,
      'buyerId': u.uid,
      'buyerEmail': u.email,
      'amount': amount,
      'note': note,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp()
    });
  }

  Future<void> report(Vehicle v, String reason) async {
    if (auth.currentUser == null ||
        reason.trim().isEmpty ||
        reason.length > 2000) {
      throw ArgumentError(
          'Sign in and enter a reason of 1\u20132,000 characters.');
    }
    await db.collection('reports').add({
      'vehicleId': v.id,
      'vehicleTitle': v.title,
      'reporterId': auth.currentUser?.uid,
      'reason': reason,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp()
    });
  }
}
