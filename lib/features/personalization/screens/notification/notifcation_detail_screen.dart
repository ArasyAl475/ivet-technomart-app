import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:t_utils/common/widgets/containers/t_container.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../data/services/notifications/notification_model.dart';
import '../../../../routes/routes.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/notifcation_controller.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(NotificationController());
    controller.selectedNotification.value = Get.arguments ?? NotificationModel.empty();
    controller.selectedNotificationId.value = Get.parameters['id'] ?? '';

    // Initialize the controller data outside the build method
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.init());

    return Scaffold(
      appBar: TAppBar(
        title: const Text('Notification Details'),
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return TContainer(
              padding: const EdgeInsets.all(TSizes.md),
              backgroundColor: dark ? TColors.darkerGrey : TColors.light,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Type Chip
                  if (controller.selectedNotification.value.type.isNotEmpty)
                    Chip(
                      label: Text(controller.selectedNotification.value.type),
                      backgroundColor: TColors.primary.withValues(alpha: 0.2),
                      labelStyle: const TextStyle(color: TColors.primary),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                    ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  // Title
                  Text(
                    controller.selectedNotification.value.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  const Divider(),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  // Body
                  Text(
                    controller.selectedNotification.value.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections * 2),

                  // Redirect Button
                  if (controller.selectedNotification.value.route.isNotEmpty &&
                      controller.selectedNotification.value.route != TRoutes.notification &&
                      controller.selectedNotification.value.route != TRoutes.notificationDetails)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Iconsax.arrow_right),
                        onPressed: () => Get.toNamed(
                          controller.selectedNotification.value.route,
                          parameters: {'id': controller.selectedNotification.value.routeId},
                        ),
                        label: const Text('View Details'),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
