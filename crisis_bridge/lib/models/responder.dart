import 'package:cloud_firestore/cloud_firestore.dart';

class Responder {
  final String uid;
  final String email;
  final String displayName;
  final String role; // staff | admin
  final String propertyId;
  final DateTime createdAt;

  const Responder({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.propertyId,
    required this.createdAt,
  });

  factory Responder.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Responder(
      uid: doc.id,
      email: d['email'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      role: d['role'] as String? ?? 'staff',
      propertyId: d['propertyId'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'role': role,
        'propertyId': propertyId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}