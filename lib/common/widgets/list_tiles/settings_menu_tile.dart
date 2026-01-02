import 'package:flutter/material.dart';
import 'package:tstore_ecommerce_app/data/repositories/authentication/authentication_repository.dart';

import '../../../utils/constants/colors.dart';

class TSettingsMenuTile extends StatelessWidget {
  TSettingsMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subTitle,
    this.trailing,
    this.onTap,
    this.guestMode = true
  });

  final IconData icon;
  final String title, subTitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool guestMode;
  final authRepo = AuthenticationRepository.instance;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 28, color: TColors.primary),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subTitle, style: Theme.of(context).textTheme.labelMedium),
      trailing: trailing,
      onTap: guestMode ? (authRepo.isGuestUser ? authRepo.showSignInRequiredPopup : onTap) : onTap,
    );
  }
}
