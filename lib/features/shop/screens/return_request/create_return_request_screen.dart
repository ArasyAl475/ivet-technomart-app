import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../controllers/return_controller.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';

class CreateReturnRequestScreen extends StatelessWidget {
  const CreateReturnRequestScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReturnController());
    controller.initializeReturnRequest(order);

    return Scaffold(
      appBar: TAppBar(
        showActions: false,
        showSkipButton: false,
        showBackArrow: true,
        title: Text(TTexts.returnRequest.tr),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Order Summary
            _buildOrderSummary(context, order),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Return Type Selection
            _buildReturnTypeSection(context, controller),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Item Selection
            _buildItemSelectionSection(context, controller, order),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Reason Selection
            _buildReasonSection(context, controller),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Photo Upload
            _buildPhotoSection(context, controller),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Submit Button
            _buildSubmitButton(context, controller),
          ],
        ),
      ),
    );
  }


  Widget _buildOrderSummary(BuildContext context, OrderModel order) {
    return TRoundedContainer(
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Order ${order.id}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          TextButton.icon(onPressed: ()=> _showReturnPolicy(context), label: Text('Return Policy'),icon: Icon(Iconsax.info_circle),iconAlignment: IconAlignment.end,)
        ],
      ),
    );
  }

  Widget _buildReturnTypeSection(BuildContext context, ReturnController controller) {
    return TRoundedContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Return Type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: TSizes.sm),
          Obx(() => Row(
            children: [
              Expanded(
                child: _buildReturnTypeChip(
                  context,
                  'Return for Refund',
                  ReturnType.returnForRefund,
                  controller.selectedReturnType.value,
                  controller,
                ),
              ),
              const SizedBox(width: TSizes.sm),
              Expanded(
                child: _buildReturnTypeChip(
                  context,
                  'Exchange',
                  ReturnType.exchange,
                  controller.selectedReturnType.value,
                  controller,
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildReturnTypeChip(BuildContext context, String label, ReturnType type,
      ReturnType selectedType, ReturnController controller) {
    final isSelected = selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        controller.selectedReturnType.value = type;
      },
      backgroundColor: isSelected ? TColors.primary : Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildItemSelectionSection(BuildContext context, ReturnController controller, OrderModel order) {
    return TRoundedContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Items to Return', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: TSizes.sm),
          Text('Choose the items you want to return or exchange',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: TSizes.md),

          ...order.products.map((item) => Obx(() =>
              _buildItemCheckbox(context, item, controller))
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildItemCheckbox(BuildContext context, CartItemModel item, ReturnController controller) {
    final isSelected = controller.selectedItems.any((selected) => selected.productId == item.productId);

    return CheckboxListTile(
      title: Text(item.title),
      subtitle: Text('Qty: ${item.quantity} • \$${item.price}'),
      value: isSelected,
      onChanged: (value) => controller.toggleItemSelection(item),
      secondary: CircleAvatar(
        backgroundImage: NetworkImage(item.image!),
        radius: 20,
      ),
    );
  }

  Widget _buildReasonSection(BuildContext context, ReturnController controller) {
    return TRoundedContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reason for Return', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: TSizes.sm),
          Obx(() => DropdownButtonFormField<ReturnReason>(
            value: controller.selectedReason.value,
            items: ReturnReason.values.map((reason) {
              return DropdownMenuItem(
                value: reason,
                child: Text(_getReasonText(reason)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.selectedReason.value = value;
              }
            },
            decoration: const InputDecoration(
              labelText: 'Select reason',
              border: OutlineInputBorder(),
            ),
          )),
          const SizedBox(height: TSizes.md),
          TextFormField(
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Additional details (required)',
              hintText: 'Please provide more details about your return...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => controller.customDescription.value = value,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context, ReturnController controller) {
    return TRoundedContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Photos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: TSizes.sm),
          Text('Add photos showing the issue (optional but recommended)',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: TSizes.md),

          Obx(() => Wrap(
            spacing: TSizes.sm,
            runSpacing: TSizes.sm,
            children: [
              // Add photo buttons
              _buildAddPhotoButton(context, controller),
              // Selected images
              ...controller.selectedImages.asMap().entries.map((entry) =>
                  _buildImagePreview(context, entry.key, entry.value, controller)
              ).toList(),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton(BuildContext context, ReturnController controller) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(context, controller),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(TSizes.sm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.camera, size: 24, color: Colors.grey[600]),
            const SizedBox(height: TSizes.xs),
            Text('Add', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, int index, XFile image, ReturnController controller) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TSizes.sm),
            image: DecorationImage(
              image: FileImage(File(image.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => controller.removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(TSizes.xs),
              ),
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, ReturnController controller) {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : () => controller.submitReturnRequest(),
        child: controller.isLoading.value
            ? const CircularProgressIndicator()
            : const Text('Submit Return Request'),
      ),
    ));
  }

  void _showImageSourceDialog(BuildContext context, ReturnController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Photo'),
        content: const Text('Choose photo source'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.pickImages();
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.takePhoto();
            },
            child: const Text('Camera'),
          ),
        ],
      ),
    );
  }

  void _showReturnPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Policy'),
        content: const SingleChildScrollView(
          child: Text(
            '• Items must be returned within 30 days of delivery\n'
                '• Products must be in original condition with tags\n'
                '• Refunds will be processed within 5-7 business days\n'
                '• Shipping costs are non-refundable\n'
                '• Exchanges are subject to product availability',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getReasonText(ReturnReason reason) {
    switch (reason) {
      case ReturnReason.damagedProduct:
        return 'Damaged Product';
      case ReturnReason.wrongItem:
        return 'Wrong Item Received';
      case ReturnReason.sizeIssue:
        return 'Size Issue';
      case ReturnReason.qualityIssue:
        return 'Quality Issue';
      case ReturnReason.notAsDescribed:
        return 'Not as Described';
      case ReturnReason.changedMind:
        return 'Changed Mind';
      case ReturnReason.other:
        return 'Other Reason';
    }
  }
}