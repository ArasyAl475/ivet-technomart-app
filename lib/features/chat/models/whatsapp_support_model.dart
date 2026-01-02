// Define the Unit model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:t_utils/utils/formatters/formatter.dart';

class WhatsappSupportModel {
  String id;
  String name;
  String number;
  bool isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Constructor
  WhatsappSupportModel({
    required this.id,
    required this.name,
    required this.number,
    this.isActive = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Helper function to return an empty AttributeModel
  static WhatsappSupportModel empty() => WhatsappSupportModel(id: '', name: '', number: '');

  String get formattedDate => TFormatter.formatDateAndTime(createdAt);

  String get formattedUpdatedAtDate => TFormatter.formatDateAndTime(updatedAt);

  /// Factory method to create AttributeModel from Firestore document snapshot
  factory WhatsappSupportModel.fromDocSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return WhatsappSupportModel.fromJson(doc.id, data);
  }

  /// Factory method to create a list of AttributeModel from QuerySnapshot (for retrieving multiple attributes)
  static WhatsappSupportModel fromQuerySnapshot(QueryDocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WhatsappSupportModel.fromJson(doc.id, data);
  }

  // Method to convert the model to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }

  // Factory constructor to create an instance of Unit from a JSON object
  factory WhatsappSupportModel.fromJson(String id, Map<String, dynamic> json) {
    return WhatsappSupportModel(
      id: id,
      name: json['name'],
      number: json['number'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt']?.toDate(),
      updatedAt: json['updatedAt']?.toDate(),
    );
  }
}
