import 'package:get/get.dart';
import '../../../data/repositories/whatsapp_support/whatsapp_support_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/popups/loaders.dart';
import '../models/whatsapp_support_model.dart';

class WhatsappSupportController extends GetxController {
  static WhatsappSupportController get instance => Get.find();

  // Inject the repository
  final WhatsappSupportRepository whatsappSupportRepository = Get.put(WhatsappSupportRepository());
  RxBool isLoading = true.obs;
    RxList<WhatsappSupportModel> allWhatsappSupportNumbers = <WhatsappSupportModel>[].obs;

  @override
  void onInit() {
    getAllWhatsappSupportNumbers();
    super.onInit();
  }

  /// -- Load Brands
  Future<void> getAllWhatsappSupportNumbers() async {
    try {
      // Show loader while loading Brands
      isLoading.value = true;

      final fetchedAllWhatsappSupportNumbers = await whatsappSupportRepository.fetchAllItems();

      // Update the brands list
      allWhatsappSupportNumbers.assignAll(fetchedAllWhatsappSupportNumbers);

    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.ohSnap.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
