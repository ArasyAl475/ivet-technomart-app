import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/return_controller.dart';
import 'package:tstore_ecommerce_app/utils/constants/enums.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../routes/routes.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/formatters/formatter.dart';
import '../../../../../utils/helpers/cloud_helper_functions.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../return_request_detail_screen.dart';

class TReturnRequestListItems extends StatelessWidget {
  const TReturnRequestListItems({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReturnController());
    return FutureBuilder(
        future: controller.getUserReturnsRequest(),
        builder: (_, snapshot) {
          /// Nothing Found Widget
          final emptyWidget = _buildStartReturnSection(context);

          /// Helper Function: Handle Loader, No Record, OR ERROR Message
          final response = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, nothingFound: emptyWidget);
          if (response != null) return response;

          /// Congratulations 🎊 Record found.
          final requests = snapshot.data!;
          return ListView.separated(
            shrinkWrap: true,
            itemCount: requests.length,
            separatorBuilder: (_, index) => const SizedBox(height: TSizes.spaceBtwItems),
            itemBuilder: (_, index) {
              final request = requests[index];
              return TRoundedContainer(
                showBorder: true,
                backgroundColor: THelperFunctions.isDarkMode(context) ? TColors.dark : TColors.light,
                child: Column(
                  children: [
                    /// -- Top Row
                    Row(
                      children: [
                        /// 1 - Image
                        const Icon(Iconsax.ship),
                        const SizedBox(width: TSizes.spaceBtwItems / 2),

                        /// 2 - Status & Date
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.status.name[0].toUpperCase() + request.status.name.substring(1),
                                overflow: TextOverflow.ellipsis,
                                style:
                                Theme.of(context).textTheme.bodyLarge!.apply(color: TColors.primary, fontWeightDelta: 1),
                              ),
                              Text(TFormatter.formatDateAndTime(request.requestDate), style: Theme.of(context).textTheme.headlineSmall),
                            ],
                          ),
                        ),

                        /// 3 - Icon
                        IconButton(onPressed: () => Get.to(() => ReturnRequestDetailScreen(returnRequest: request,)), icon: const Icon(Iconsax.arrow_right_34, size: TSizes.iconSm)),
                      ],
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),

                    /// -- Bottom Row
                    Row(
                      children: [
                        /// Order No
                        Expanded(
                          child: Row(
                            children: [
                              /// 1 - Icon
                              const Icon(Iconsax.refresh_circle),
                              const SizedBox(width: TSizes.spaceBtwItems / 2),

                              /// Order
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      TTexts.requestType.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                    Text(
                                      _getReturnType(request.returnType),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// Delivery Date
                        Expanded(
                          child: Row(
                            children: [
                              /// 1 - Icon
                              const Icon(Iconsax.calendar),
                              const SizedBox(width: TSizes.spaceBtwItems / 2),

                              /// Status & Date
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      TTexts.requestedDate.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                    Text(
                                      TFormatter.formatDate(request.requestDate),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        });
  }


  Widget _buildStartReturnSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Column(
        children: [
          Icon(Iconsax.box_remove, size: 64, color: Colors.grey[400]),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'Start a Return or Exchange',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'Select an order from your order history to begin the return or exchange process.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TSizes.spaceBtwSections),
          SizedBox(
            width: 250,
            child: ElevatedButton(
              onPressed: () => Get.toNamed(TRoutes.order),
              child: const Text('Select Order from History'),
            ),
          ),
        ],
      ),
    );
  }

  String _getReturnType(ReturnType type) {
    switch (type) {
      case ReturnType.returnForRefund:
        return 'Return';
      case ReturnType.exchange:
        return 'Exchange';
      case ReturnType.returnAndExchange:
        return 'Return & Exchange';
    }
  }

}
