import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  const Vehicle(
      {required this.id,
      required this.sellerId,
      required this.title,
      required this.category,
      required this.make,
      required this.model,
      required this.year,
      required this.price,
      required this.location,
      required this.transmission,
      required this.fuel,
      required this.condition,
      required this.mileage,
      required this.description,
      required this.phone,
      required this.whatsapp,
      required this.images,
      required this.status,
      required this.featured,
      required this.verified,
      required this.managedSale,
      required this.createdAt});
  final String id,
      sellerId,
      title,
      category,
      make,
      model,
      location,
      transmission,
      fuel,
      condition,
      description,
      phone,
      whatsapp,
      status;
  final int year, mileage;
  final double price;
  final List<String> images;
  final bool featured, verified, managedSale;
  final DateTime createdAt;
  double get commission =>
      managedSale ? ((price * 100).round() / 10).round() / 100 : 0;
  double get sellerNet =>
      ((price * 100).round() - (commission * 100).round()) / 100;
  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'title': title,
        'category': category,
        'make': make,
        'model': model,
        'year': year,
        'price': price,
        'location': location,
        'transmission': transmission,
        'fuel': fuel,
        'condition': condition,
        'mileage': mileage,
        'description': description,
        'phone': phone,
        'whatsapp': whatsapp,
        'images': images,
        'status': status,
        'featured': featured,
        'verified': verified,
        'managedSale': managedSale,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp()
      };
  factory Vehicle.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data() ?? {};
    return Vehicle(
        id: d.id,
        sellerId: j['sellerId'] ?? '',
        title: j['title'] ?? '',
        category: j['category'] ?? 'Car',
        make: j['make'] ?? '',
        model: j['model'] ?? '',
        year: (j['year'] ?? 0) as int,
        price: (j['price'] as num? ?? 0).toDouble(),
        location: j['location'] ?? '',
        transmission: j['transmission'] ?? '',
        fuel: j['fuel'] ?? '',
        condition: j['condition'] ?? '',
        mileage: (j['mileage'] ?? 0) as int,
        description: j['description'] ?? '',
        phone: j['phone'] ?? '',
        whatsapp: j['whatsapp'] ?? '',
        images: List<String>.from(j['images'] ?? []),
        status: j['status'] ?? 'pending',
        featured: j['featured'] ?? false,
        verified: j['verified'] ?? false,
        managedSale: j['managedSale'] ?? true,
        createdAt: (j['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now());
  }
}

class AppUser {
  const AppUser(
      {required this.uid,
      required this.name,
      required this.email,
      required this.phone,
      required this.role,
      required this.verified,
      this.accountStatus = 'active'});
  final String uid, name, email, phone, role, accountStatus;
  final bool verified;
  bool get isAdmin => role == 'admin';
  bool get isSeller => role == 'seller' || role == 'partner' || isAdmin;
  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data() ?? {};
    return AppUser(
        uid: d.id,
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'] ?? '',
        role: j['role'] ?? 'buyer',
        verified: j['verified'] ?? false,
        accountStatus: j['accountStatus'] ?? 'active');
  }
}
