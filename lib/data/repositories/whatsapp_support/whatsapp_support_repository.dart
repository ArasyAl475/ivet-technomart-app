import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../features/chat/models/whatsapp_support_model.dart';
import '../../abstract/base_repository.dart';

class WhatsappSupportRepository extends TBaseRepositoryController<WhatsappSupportModel> {
  static WhatsappSupportRepository get instance => Get.find();

  @override
  Future<String> addItem(WhatsappSupportModel item) async {
    final result = await db.collection("WhatsappSupport").add(item.toJson());
    return result.id;
  }

  @override
  Future<List<WhatsappSupportModel>> fetchAllItems() async {
    final snapshot = await db.collection("WhatsappSupport").orderBy('createdAt', descending: true).get();
    final result = snapshot.docs.map((e) => WhatsappSupportModel.fromDocSnapshot(e)).toList();
    return result;
  }

  @override
  Future<WhatsappSupportModel> fetchSingleItem(String id) async {
    final snapshot = await db.collection("WhatsappSupport").doc(id).get();
    final result = WhatsappSupportModel.fromDocSnapshot(snapshot);
    return result;
  }

  @override
  WhatsappSupportModel fromQueryDocSnapshot(QueryDocumentSnapshot<Object?> doc) {
    return WhatsappSupportModel.fromQuerySnapshot(doc);
  }

  @override
  Query getPaginatedQuery(limit) => db.collection('WhatsappSupport').orderBy('createdAt', descending: true).limit(limit);

  @override
  Future<void> updateItem(WhatsappSupportModel item) async {
    await db.collection("WhatsappSupport").doc(item.id).update(item.toJson());
  }

  @override
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {
    await db.collection("WhatsappSupport").doc(id).update(json);
  }

  @override
  Future<void> deleteItem(WhatsappSupportModel item) async {
    await db.collection("WhatsappSupport").doc(item.id).delete();
  }
}
