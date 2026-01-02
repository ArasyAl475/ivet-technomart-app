import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tstore_ecommerce_app/common/widgets/appbar/appbar.dart';
import 'package:tstore_ecommerce_app/features/shop/screens/return_request/widgets/return_request_list.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';

class ReturnRequestScreen extends StatelessWidget {
  const ReturnRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: Text(TTexts.returnAndExchange.tr),
        showSkipButton: false,
        showActions: false,
        showBackArrow: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: TReturnRequestListItems(),
      ),
    );
  }
}