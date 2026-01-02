import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../features/shop/models/return_request_model.dart';
import '../../../utils/constants/enums.dart';
import '../../abstract/base_repository.dart';

class ReturnRequestRepository extends TBaseRepositoryController<ReturnRequest> {
  static ReturnRequestRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get collectionName => 'ReturnRequests';

  @override
  Future<List<ReturnRequest>> fetchAllItems() async {
    final querySnapshot = await _db.collection(collectionName).orderBy('requestDate', descending: true).get();

    return querySnapshot.docs.map((doc) => ReturnRequest.fromJson(doc.id, doc.data())).toList();
  }

  @override
  Future<ReturnRequest> fetchSingleItem(String id) async {
    final doc = await _db.collection(collectionName).doc(id).get();
    if (doc.exists) {
      return ReturnRequest.fromJson(doc.id, doc.data()!);
    }
    throw 'Return request not found';
  }

  @override
  Future<String> addItem(ReturnRequest item) async {
    final docRef = await _db.collection(collectionName).add(item.toJson());
    return docRef.id;
  }

  @override
  Future<void> updateItem(ReturnRequest item) async {
    await _db.collection(collectionName).doc(item.id).update(item.toJson());
  }

  @override
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {
    await _db.collection(collectionName).doc(id).update(json);
  }

  @override
  Future<void> deleteItem(ReturnRequest item) async {
    await _db.collection(collectionName).doc(item.id).delete();
  }

  @override
  Query getPaginatedQuery(int limit) {
    return _db.collection(collectionName).orderBy('requestDate', descending: true).limit(limit);
  }

  @override
  ReturnRequest fromQueryDocSnapshot(QueryDocumentSnapshot<Object?> doc) {
    return ReturnRequest.fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  // Custom methods specific to return requests based on status
  Future<List<ReturnRequest>> getReturnRequestsByStatus(ReturnStatus status) async {
    final querySnapshot =
        await _db.collection(collectionName).where('status', isEqualTo: status.name).orderBy('requestDate', descending: true).get();

    return querySnapshot.docs.map((doc) => ReturnRequest.fromJson(doc.id, doc.data())).toList();
  }

  // Custom methods specific to return requests based on user ID
  Future<List<ReturnRequest>> getReturnRequestsByUserId(String userId) async {
    final querySnapshot =
        await _db.collection(collectionName).where('userId', isEqualTo: userId).orderBy('requestDate', descending: true).get();

    return querySnapshot.docs.map((doc) => ReturnRequest.fromJson(doc.id, doc.data())).toList();
  }

  // Custom methods specific to return requests based on order ID
  Future<List<ReturnRequest>> getReturnRequestsByOrderId(String orderId) async {
    final querySnapshot = await _db.collection(collectionName).where('orderId', isEqualTo: orderId).get();

    return querySnapshot.docs.map((doc) => ReturnRequest.fromJson(doc.id, doc.data())).toList();
  }

  // Stream methods for real-time updates of all return requests
  Stream<List<ReturnRequest>> getReturnRequestsStream() {
    return _db
        .collection(collectionName)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ReturnRequest.fromJson(doc.id, doc.data())).toList());
  }

  // Stream methods for real-time updates of a specific return request by ID
  Stream<ReturnRequest?> getReturnRequestStream(String requestId) {
    return _db.collection(collectionName).doc(requestId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return ReturnRequest.fromJson(snapshot.id, snapshot.data()!);
      }
      return null;
    });
  }

  // Statistics methods
  Future<Map<String, int>> getReturnStatistics() async {
    final allRequests = await fetchAllItems();

    return {
      'total': allRequests.length,
      'pending': allRequests.where((r) => r.status == ReturnStatus.requested).length,
      'approved': allRequests.where((r) => r.status == ReturnStatus.approved).length,
      'rejected': allRequests.where((r) => r.status == ReturnStatus.rejected).length,
      'refunded': allRequests.where((r) => r.status == ReturnStatus.refundProcessed).length,
      'exchanged': allRequests.where((r) => r.status == ReturnStatus.exchangeProcessed).length,
    };
  }

  Future<int> getReturnCountByStatus(ReturnStatus status) async {
    final querySnapshot = await _db.collection(collectionName).where('status', isEqualTo: status.name).get();

    return querySnapshot.size;
  }
}
