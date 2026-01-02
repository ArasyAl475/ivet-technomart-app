import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:t_utils/t_utils.dart' hide TFullScreenLoader;
import 'package:tstore_ecommerce_app/common/widgets/success_screen/success_screen.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/routes/routes.dart';
import 'package:tstore_ecommerce_app/utils/constants/image_strings.dart';
import 'package:tstore_ecommerce_app/utils/constants/text_strings.dart';
import '../../../data/repositories/return/return_request_repository.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../models/cart_item_model.dart';
import '../models/return_request_model.dart';
import '../models/order_model.dart';

class ReturnController extends GetxController {
  static ReturnController get instance => Get.find();

  // Repository instance
  final ReturnRequestRepository _returnRepository = Get.put(ReturnRequestRepository());
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Reactive variables
  final Rx<ReturnRequest> returnRequest = ReturnRequest.empty().obs;
  final RxList<ReturnRequest> returnRequests = <ReturnRequest>[].obs;
  final RxList<XFile> selectedImages = <XFile>[].obs;
  final RxList<CartItemModel> selectedItems = <CartItemModel>[].obs;
  final Rx<ReturnType> selectedReturnType = ReturnType.returnForRefund.obs;
  final Rx<ReturnReason> selectedReason = ReturnReason.other.obs;
  final RxString customDescription = ''.obs;
  final RxBool isLoading = false.obs;


  // Initialize return request with order data
  void initializeReturnRequest(OrderModel order) {
    returnRequest.value = ReturnRequest(
      id: _returnRepository.db.collection('ReturnRequests').doc().id,
      orderId: order.id,
      userId: order.userId,
      userName: order.userName,
      userEmail: order.userEmail,
      userPhone: order.shippingAddress.phoneNumber,
      requestDate: DateTime.now(),
      returnType: selectedReturnType.value,
      status: ReturnStatus.requested,
      reason: selectedReason.value,
      description: customDescription.value,
      photoUrls: [],
      returnItems: selectedItems,
    );
  }

  // Select/deselect items for return
  void toggleItemSelection(CartItemModel item) {
    if (selectedItems.any((selectedItem) => selectedItem.productId == item.productId)) {
      selectedItems.removeWhere((selectedItem) => selectedItem.productId == item.productId);
    } else {
      selectedItems.add(item);
    }
    update();
  }

  // Image picking methods
  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(maxWidth: 1200, maxHeight: 1200, imageQuality: 80);

      if (images.isNotEmpty) {
        selectedImages.addAll(images);
        update();
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: 'Failed to pick images');
    }
  }

  Future<void> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);

      if (image != null) {
        selectedImages.add(image);
        update();
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: 'Failed to take photo');
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
    update();
  }

  // Upload images to Firebase Storage
  Future<List<String>> uploadImages() async {
    final List<String> imageUrls = [];

    for (final XFile image in selectedImages) {
      try {
        final File file = File(image.path);
        final String fileName = 'returns/${returnRequest.value.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = _storage.ref().child(fileName);

        final TaskSnapshot snapshot = await ref.putFile(file);
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: 'Failed to upload image');
        rethrow;
      }
    }

    return imageUrls;
  }

  // Submit return request
  Future<void> submitReturnRequest() async {
    try {
      if (selectedItems.isEmpty) {
        TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: 'Please select at least one item to return');
        return;
      }

      if (customDescription.value.isEmpty) {
        TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: 'Please provide a description for your return');
        return;
      }

      TFullScreenLoader.openLoadingDialog(TTexts.processingYourOrder.tr, TImages.pencilAnimation);

      // Upload images if any
      final List<String> uploadedImageUrls = await uploadImages();

      // Create final return request
      final ReturnRequest finalRequest = ReturnRequest(
        id: returnRequest.value.id,
        orderId: returnRequest.value.orderId,
        userId: returnRequest.value.userId,
        userName: returnRequest.value.userName,
        userEmail: returnRequest.value.userEmail,
        userPhone: returnRequest.value.userPhone,
        requestDate: DateTime.now(),
        returnType: selectedReturnType.value,
        status: ReturnStatus.requested,
        reason: selectedReason.value,
        description: customDescription.value,
        photoUrls: uploadedImageUrls,
        returnItems: selectedItems,
      );

      // Save to Firestore
      await _returnRepository.addNewItem(finalRequest);

      // Reset form
      resetForm();

      // Show Success screen
      Get.off(
            () => SuccessScreen(
          image: TImages.orderCompletedAnimation,
          title: TTexts.returnRequest.tr,
          subTitle: TTexts.returnRequestSubTitle.tr,
          onPressed: () => Get.offAllNamed(TRoutes.homeMenu),
        ),
      );
    } catch (e) {
      TFullScreenLoader.stopLoading();
      // Show error message
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: 'Failed to submit return request: ${e.toString()}');
    }
  }

  // Cancel return request
  Future<void> cancelReturnRequest(String requestId) async {
    try{
      _returnRepository.updateSingleField(requestId, {
        'status' : ReturnStatus.canceled.name,
        'rejectedAt' : FieldValue.serverTimestamp(),
        'updatedAt' : FieldValue.serverTimestamp(),
      });

      TLoaders.successSnackBar(title: 'Success' ,message: 'Request has been cancelled.');

      Get.offAllNamed(TRoutes.homeMenu);
    }catch(e){
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: 'Failed to cancel return request: ${e.toString()}');
    }
  }

  void resetForm() {
    selectedImages.clear();
    selectedItems.clear();
    selectedReturnType.value = ReturnType.returnForRefund;
    selectedReason.value = ReturnReason.other;
    customDescription.value = '';
    returnRequest.value = ReturnRequest.empty();
  }

  // Get user's return requests
  Stream<List<ReturnRequest>> getUserReturnRequests(String userId) {
    return _returnRepository.getReturnRequestsStream().map((allRequests) {
      return allRequests.where((request) => request.userId == userId).toList();
    });
  }

  //Get specific return request by ID
  Future<ReturnRequest?> getReturnRequestById(String requestId) async {
    try {
      return await _returnRepository.getSingleItem(requestId);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: 'Failed to load return request');
      return null;
    }
  }

  // Get user's return requests
  Future<List<ReturnRequest>> getUserReturnsRequest() async {
    try {
      final allUserRequests = await _returnRepository.getReturnRequestsByUserId(AuthenticationRepository.instance.getUserID);
      return allUserRequests;
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: 'Failed to load return requests');
      return [];
    }
  }

  @override
  void dispose() {
    returnRequests.close();
    selectedImages.close();
    selectedItems.close();
    selectedReturnType.close();
    selectedReason.close();
    customDescription.close();
    isLoading.close();
    super.dispose();
  }
}