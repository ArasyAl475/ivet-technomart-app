import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';
import 'package:tstore_ecommerce_app/routes/routes.dart';

import '../../../../utils/constants/colors.dart';
import '../../../features/personalization/controllers/user_controller.dart';
import '../../../utils/constants/image_strings.dart';
import '../images/t_circular_image.dart';

class TUserProfileTile extends StatelessWidget {
  TUserProfileTile({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;
  final controller = UserController.instance;
  final authRepo = AuthenticationRepository.instance;


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isNetworkImage = controller.user.value.profilePicture.isNotEmpty;
      final image = isNetworkImage ? controller.user.value.profilePicture : TImages.user;
      return ListTile(
        leading: TCircularImage(padding: 0, image: image, width: 50, height: 50, isNetworkImage: isNetworkImage),
        title: Text(authRepo.isGuestUser ? 'Guest User' :  controller.user.value.fullName, style: Theme.of(context).textTheme.headlineSmall!.apply(color: TColors.white)),
        subtitle: Text(authRepo.isGuestUser ? "Sign in to enjoy full features" : controller.user.value.email, style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.white)),
        trailing: IconButton(onPressed: authRepo.isGuestUser ? ()=> Get.toNamed(TRoutes.welcome) : onPressed, icon: Icon(authRepo.isGuestUser ? Iconsax.login : Iconsax.edit, color: TColors.white)),
      );
    });
  }
}
