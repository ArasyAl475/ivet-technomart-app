import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tstore_ecommerce_app/features/shop/controllers/return_controller.dart';
import 'package:tstore_ecommerce_app/features/shop/models/return_request_model.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';

const Color primaryBlue = Color(0xFF0A3D62);
const Color secondaryTeal = Color(0xFF00B894);
const Color accentYellow = Color(0xFFFFBE76);
const Color neutralLight = Color(0xFFF8F9FA);

class ReturnRequestDetailScreen extends StatelessWidget {
  final ReturnRequest returnRequest;

  const ReturnRequestDetailScreen({super.key, required this.returnRequest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        showActions: false,
        showSkipButton: false,
        title: Text(returnRequest.id.substring(0, 8), style: TextStyle(color: primaryBlue)),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              // 1. Status Progress Indicator (Redesigned)
              _buildProgressStepper(context, returnRequest),

              Column(
                children: [
                  const SizedBox(height: TSizes.spaceBtwSections),

                  // 2. Request Overview (Consolidated Product, Reason, Resolution)
                  _buildRequestOverview(context, returnRequest),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  // 3. Photos
                  if (returnRequest.photoUrls.isNotEmpty) ...[
                    _buildSectionContainer(
                      context,
                      title: 'Photo Evidence (${returnRequest.photoUrls.length})',
                      icon: Iconsax.camera,
                      child: _buildPhotosSection(context, returnRequest),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),
                  ],

                  // 4. Admin Response / Tracking (Now with card styling)
                  if (returnRequest.adminNote != null && returnRequest.adminNote!.isNotEmpty) ...[
                    _buildAdminResponse(context, returnRequest),
                    const SizedBox(height: TSizes.spaceBtwSections),
                  ],

                  if (returnRequest.returnTrackingNumber != null || returnRequest.exchangeTrackingNumber != null) ...[
                    _buildTrackingInfo(context, returnRequest),
                    const SizedBox(height: TSizes.spaceBtwSections),
                  ],

                  // 5. Request Timeline (Detailed History)
                  _buildSectionContainer(
                    context,
                    title: 'Request Timeline',
                    icon: Iconsax.scroll,
                    child: _buildTimeline(context, returnRequest),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections * 2),
                ],
              ),
            ],
          ),
        ),
      ),

      // 6. Sticky Action Footer
      bottomNavigationBar: _buildActionBar(context, returnRequest),
    );
  }

  /// A generalized container for all major sections with card styling
  Widget _buildSectionContainer(BuildContext context, {required String title, required Widget child, IconData? icon, Color? iconColor}) {
    return TRoundedContainer(
      padding: const EdgeInsets.all(TSizes.md),
      backgroundColor: Colors.white,
      borderColor: TColors.grey.withValues(alpha: 0.1),
      showBorder: true,
      // borderRadius: TSizes.borderRadiusLg,
      // boxShadow: [
      //   BoxShadow(
      //     color: Colors.black.withOpacity(0.05),
      //     blurRadius: 10,
      //     offset: const Offset(0, 4),
      //   )
      // ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon ?? Iconsax.box, size: 20, color: iconColor ?? secondaryTeal),
              const SizedBox(width: TSizes.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),
          child,
        ],
      ),
    );
  }

  /// 1. Progress Stepper
  Widget _buildProgressStepper(BuildContext context, ReturnRequest request) {
    // Simplified 4-step process for visual stepper:
    // 1. Requested | 2. Approved/Rejected | 3. In Transit/Inspection | 4. Finalized (Refunded/Exchange)
    final currentStatusIndex = _getStatusStepIndex(request.status);
    final isRejected = request.status == ReturnStatus.rejected;

    return TRoundedContainer(
      padding: const EdgeInsets.symmetric(vertical: TSizes.md, horizontal: TSizes.defaultSpace),
      backgroundColor: primaryBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request ID: ${request.id.substring(0, 8)}',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            _getMainStatusTitle(request.status),
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              color: isRejected ? TColors.error : accentYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: TSizes.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final stepName = _getStepName(index);
              final isCompleted = index < currentStatusIndex;
              final isActive = index == currentStatusIndex;

              Color dotColor = Colors.white24;
              Color textColor = Colors.white54;
              IconData icon = _getStepIcon(index);

              if (isCompleted) {
                dotColor = secondaryTeal;
                textColor = Colors.white;
                icon = Iconsax.tick_circle;
              } else if (isActive) {
                dotColor = isRejected ? TColors.error : accentYellow;
                textColor = isRejected ? TColors.error : accentYellow;
                icon = isRejected ? Iconsax.close_circle : _getStepIcon(index);
              }

              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot/Line
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Connecting Line
                        if (index < 3)
                          Positioned(
                            left: 0,
                            right: -30,
                            child: Container(
                              height: 2,
                              color: isCompleted ? secondaryTeal : Colors.white10,
                            ),
                          ),

                        // Dot/Icon Container
                        Container(
                          width: isActive ? 24 : 16,
                          height: isActive ? 24 : 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                            border: Border.all(
                              color: isActive && !isRejected ? accentYellow.withValues(alpha: 0.5) : Colors.transparent,
                              width: isActive ? 3 : 0,
                            ),
                            boxShadow: isActive && !isRejected ? [
                              // BoxShadow(
                              //   color: accentYellow.withOpacity(0.4),
                              //   blurRadius: 6,
                              //   spreadRadius: 1,
                              // ),
                            ] : null,
                          ),
                          child: Icon(
                            icon,
                            size: isActive ? 14 : 10,
                            color: isActive ? primaryBlue : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.xs),
                    // Label
                    Text(
                      stepName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 2. Consolidated Request Overview
  Widget _buildRequestOverview(BuildContext context, ReturnRequest request) {
    final item = request.returnItems.first;

    return _buildSectionContainer(
      context,
      title: 'Request Overview',
      icon: Iconsax.box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Item Details Card (Internal)
          TRoundedContainer(
            padding: const EdgeInsets.all(TSizes.sm),
            backgroundColor: neutralLight,
            //borderRadius: TSizes.md,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(TSizes.sm),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CachedNetworkImage(
                      imageUrl: item.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)),
                      errorWidget: (context, url, error) => const Icon(Iconsax.image, size: 30, color: TColors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.md),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: primaryBlue), maxLines: 2, overflow: TextOverflow.ellipsis),

                      // if (item.selectedVariation != null && item.selectedVariation!.isNotEmpty) ...[
                      //   const SizedBox(height: TSizes.xs),
                      //   Text(item.selectedVariation!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TColors.darkGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      // ],

                      const SizedBox(height: TSizes.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Qty: ${item.quantity}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.darkGrey),
                          ),
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: secondaryTeal),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: TSizes.md),
          const Divider(color: TColors.grey, height: 1),
          const SizedBox(height: TSizes.md),

          // Resolution & Reason
          _buildDetailRow(context,
              label: 'Requested Resolution:',
              value: _getRequestType(request.returnType)
          ),
          _buildDetailRow(context,
              label: 'Return Reason:',
              value: _getReturnReason(request.reason),
              isMultiline: true
          ),

          // Customer Notes
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: TSizes.md),
            Text('Customer Notes:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.darkGrey)),
            const SizedBox(height: TSizes.sm),
            TRoundedContainer(
              padding: const EdgeInsets.all(TSizes.sm),
              backgroundColor: TColors.light.withValues(alpha: 0.5),
              child: Text(
                request.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Reusable detail row for consistency
  Widget _buildDetailRow(BuildContext context, {required String label, required String value, bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.darkGrey)),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Photos Section
  Widget _buildPhotosSection(BuildContext context, ReturnRequest request) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: request.photoUrls.length,
        separatorBuilder: (context, index) => const SizedBox(width: TSizes.sm),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showImageDialog(context, request.photoUrls[index]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TSizes.sm),
              child: SizedBox(
                width: 90,
                height: 90,
                child: CachedNetworkImage(
                  imageUrl: request.photoUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)),
                  errorWidget: (context, url, error) => const Icon(Iconsax.image, size: 40, color: TColors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 4. Admin Response Card
  Widget _buildAdminResponse(BuildContext context, ReturnRequest request) {
    return TRoundedContainer(
      padding: const EdgeInsets.all(TSizes.md),
      backgroundColor: secondaryTeal.withValues(alpha: 0.1),
      borderColor: secondaryTeal.withValues(alpha: 0.5),
      showBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.info_circle, size: 20, color: secondaryTeal),
              const SizedBox(width: TSizes.sm),
              Text('Admin Response', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: secondaryTeal, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: TSizes.md),
          Text(request.adminNote!, style: Theme.of(context).textTheme.bodyMedium),
          if (request.approvedAt != null || request.rejectedAt != null) ...[
            const SizedBox(height: TSizes.sm),
            Text(
              'Responded on ${_formatDateTime(request.approvedAt ?? request.rejectedAt!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TColors.darkGrey),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. Tracking Info
  Widget _buildTrackingInfo(BuildContext context, ReturnRequest request) {
    final hasTracking = request.returnTrackingNumber != null;
    final hasExchangeTracking = request.exchangeTrackingNumber != null;
    final hasExchangeCarrier = request.exchangeCarrier != null;

    return _buildSectionContainer(
      context,
      title: 'Shipment Tracking',
      icon: Iconsax.truck,
      iconColor: TColors.info,
      child: Column(
        children: [
          if (hasTracking)
            _buildDetailRow(
              context,
              label: 'Return Shipment Tracking:',
              value: request.returnTrackingNumber!,
            ),
          if (hasTracking && hasExchangeTracking) const Divider(color: TColors.grey, height: 20),
          if (hasExchangeTracking)
            _buildDetailRow(
              context,
              label: 'Exchange Product Tracking:',
              value: request.exchangeTrackingNumber!,
            ),
          if(hasExchangeCarrier) _buildDetailRow(context, label: 'Exchange Carrier:', value: request.exchangeCarrier!)
        ],
      ),
    );
  }

  /// 6. Detailed Timeline
  Widget _buildTimeline(BuildContext context, ReturnRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineItem(context, Iconsax.calendar, 'Request Submitted', _formatDateTime(request.requestDate), Colors.black87),

        if (request.approvedAt != null)
          _buildTimelineItem(context, Iconsax.tick_circle, 'Request Approved', _formatDateTime(request.approvedAt!), secondaryTeal)
        else if (request.rejectedAt != null)
          _buildTimelineItem(context, Iconsax.close_circle, 'Request Rejected', _formatDateTime(request.rejectedAt!), TColors.error),

        if (request.refundProcessedAt != null)
          _buildTimelineItem(context, Iconsax.money_send, 'Refund Processed', _formatDateTime(request.refundProcessedAt!), TColors.info), // Blue/Teal

        if (request.exchangeTrackingNumber != null)
          _buildTimelineItem(context, Iconsax.box, 'Exchange Shipped', 'Tracking: ${request.exchangeTrackingNumber!}', primaryBlue),

        if (request.status == ReturnStatus.completed)
          _buildTimelineItem(context, Iconsax.tick_square, 'Return Process Completed', _formatDateTime(DateTime.now()), secondaryTeal),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Marker and Line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
              // Use a SizedBox as a spacer line - simplified Flutter approach
              if (title != 'Return Process Completed' && subtitle != 'Tracking: ${returnRequest.exchangeTrackingNumber ?? 0}')
                Container(
                  width: 2,
                  height: 35,
                  color: color.withValues(alpha: 0.5),
                ),
            ],
          ),
          const SizedBox(width: TSizes.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                )),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.darkGrey,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 7. Sticky Action Footer Bar
  Widget _buildActionBar(BuildContext context, ReturnRequest request) {
    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor;
    String? hintMessage;

    switch (request.status) {
      case ReturnStatus.requested:
      case ReturnStatus.underReview:
        buttonText = 'Cancel Request';
        buttonColor = TColors.error;
        onPressed = () => _showCancelConfirmation(context);
        hintMessage = 'You can still cancel this request while it is under review.';
        break;
      case ReturnStatus.approved:
        buttonText = '';
        buttonColor = primaryBlue;
        onPressed = null;
        hintMessage = 'Your request is approved. Please wait for the shipment.';
        break;
      case ReturnStatus.rejected:
        buttonText = 'Contact Support';
        buttonColor = TColors.darkGrey;
        onPressed = () => Get.snackbar('Info', 'Opening chat with support.', backgroundColor: TColors.info, colorText: Colors.white);
        hintMessage = 'This request has been rejected. Contact support for further review.';
        break;
      case ReturnStatus.refundProcessed:
      case ReturnStatus.exchangeProcessed:
      case ReturnStatus.completed:
        buttonText = 'Track Status (Completed)';
        buttonColor = TColors.darkGrey;
        onPressed = null;
        hintMessage = 'The return process is complete. No further action is required.';
      case ReturnStatus.canceled:
        buttonText = 'Track Status (Canceled)';
        buttonColor = TColors.darkGrey;
        onPressed = null;
        hintMessage = 'The return request has been canceled. No further action is required.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                side: BorderSide(
                  color: buttonColor
                ),
                padding: const EdgeInsets.symmetric(vertical: TSizes.md),
               // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusSm)),
              ),
              child: Text(buttonText, style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          if (hintMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: TSizes.sm),
              child: Text(
                hintMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TColors.darkGrey),
              ),
            ),
        ],
      ),
    );
  }

  // --- Helper

  int _getStatusStepIndex(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.requested:
        return 0;
      case ReturnStatus.underReview:
        return 1;
      case ReturnStatus.approved:
      case ReturnStatus.rejected:
        case ReturnStatus.canceled:
        return 2;
      case ReturnStatus.refundProcessed:
      case ReturnStatus.exchangeProcessed:
        return 3;
      case ReturnStatus.completed:
        return 4;
    }
  }

  String _getStepName(int index) {
    switch (index) {
      case 0:
        return 'Requested';
      case 1:
        return 'Review';
      case 2:
        return 'Action'; // Shipping Label / Rejection
      case 3:
        return 'Finalized'; // Refund/Exchange
      default:
        return '';
    }
  }

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0:
        return Iconsax.document_text;
      case 1:
        return Iconsax.clock;
      case 2:
        return Iconsax.box_search;
      case 3:
        return Iconsax.tick_square;
      default:
        return Iconsax.close_circle;
    }
  }

  String _getMainStatusTitle(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.requested:
      case ReturnStatus.underReview:
        return 'Awaiting Review';
      case ReturnStatus.approved:
        return 'Approved - Label Ready';
      case ReturnStatus.rejected:
        return 'Request Rejected';
      case ReturnStatus.refundProcessed:
        return 'Refund Issued';
      case ReturnStatus.exchangeProcessed:
        return 'Exchange Shipped';
      case ReturnStatus.completed:
        return 'Completed';
      case ReturnStatus.canceled:
        return 'Canceled';

    }
  }

  // --- Utility Functions

  void _showImageDialog(BuildContext context, String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (context, url, error) => const Center(child: Text('Could not load image', style: TextStyle(color: Colors.white))),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    Get.defaultDialog(
      title: "Confirm Cancellation",
      titleStyle: TextStyle(color: TColors.error, fontWeight: FontWeight.bold),
      middleText: "Are you sure you want to cancel return request ${returnRequest.id.substring(0, 8)}? This action cannot be undone.",
      backgroundColor: Colors.white,
      radius: TSizes.borderRadiusLg,
      contentPadding: EdgeInsets.all(TSizes.cardRadiusLg),
      confirm: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            Get.back();
            final controller = Get.find<ReturnController>();
            await controller.cancelReturnRequest(returnRequest.id);

          },
          style: ElevatedButton.styleFrom(backgroundColor: TColors.error),
          child: const Text("Yes, Cancel It", style: TextStyle(color: Colors.white)),
        ),
      ),
      cancel: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Get.back(),
          child: Text("Keep Request", style: TextStyle(color: primaryBlue)),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getRequestType(ReturnType type) {
    switch (type) {
      case ReturnType.returnForRefund:
        return 'Return for Refund';
      case ReturnType.exchange:
        return 'Exchange';
      case ReturnType.returnAndExchange:
        return 'Return and Exchange';
   }
  }

  String _getReturnReason(ReturnReason reason) {
    switch (reason) {
      case ReturnReason.damagedProduct:
        return 'Damaged Product';
      case ReturnReason.wrongItem:
        return 'Wrong Item';
      case ReturnReason.sizeIssue:
        return 'Size Issue';
        case ReturnReason.qualityIssue:
        return 'Quality Issue';
      case ReturnReason.notAsDescribed:
        return 'Not as Described';
      case ReturnReason.changedMind:
        return 'Changed My Mind';
        case ReturnReason.other:
        return 'Other';
    }
  }
}

// Extension for string title case (carried over from previous design)
extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return '';
    return split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
