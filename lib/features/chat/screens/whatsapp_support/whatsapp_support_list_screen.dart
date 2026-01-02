import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/popups/loaders.dart';
import '../../controllers/whatsapp_support_controller.dart';
import '../../models/whatsapp_support_model.dart';

class WhatsappSupportListScreen extends StatelessWidget {
  const WhatsappSupportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final whatsappSupportController = Get.put(WhatsappSupportController());

    return Scaffold(
      appBar: TAppBar(
        title: const Text('Whatsapp Support'),
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
      ),
      body: Obx(() {
        if (whatsappSupportController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (whatsappSupportController.allWhatsappSupportNumbers.isEmpty) {
          return const Center(child: Text('No support numbers available'));
        } else {
          return ListView.builder(
            itemCount: whatsappSupportController.allWhatsappSupportNumbers.length,
            itemBuilder: (context, index) {
              WhatsappSupportModel supportContact = whatsappSupportController.allWhatsappSupportNumbers[index];

              return ListTile(
                leading: const Icon(Icons.support_agent),
                title: Text(
                  supportContact.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  supportContact.number,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final Uri whatsappUrl = Uri.parse('https://wa.me/${supportContact.number}');
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                  } else {
                    TLoaders.errorSnackBar(title: 'Error', message: 'Could not launch WhatsApp.');
                  }
                },
              );
            },
          );
        }
      }),
    );
  }
}
