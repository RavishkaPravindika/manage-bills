import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// Company — Firestore companies/{id} document model
// ============================================================

class Company {
  const Company({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory Company.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Company(
      id: doc.id,
      name: data['name'] as String? ?? '',
    );
  }

  factory Company.fromMap(String id, Map<String, dynamic> data) => Company(
        id: id,
        name: data['name'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
      };

  Company copyWith({String? id, String? name}) => Company(
        id: id ?? this.id,
        name: name ?? this.name,
      );

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Company && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
