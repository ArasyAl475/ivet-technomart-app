import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app.dart';
import 'data/repositories/authentication/authentication_repository.dart';
import 'data/services/razorpay/razorpay_service.dart';
import 'features/personalization/controllers/language_controller.dart';
import 'firebase_options.dart';
import 'utils/constants/api_constants.dart';

/// -- Entry point of Flutter App
Future<void> main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /// -- GetX Local Storage
  await GetStorage.init();

  /// -- Overcome from transparent spaces at the bottom in iOS full Mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  /// -- Await Splash until other items Load
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  /// -- Stripe Configuration
  /// -- Warning: Do not use Secret Key here.
  /// -- Update Key in Your Stripe Cloud Function in Admin Panel
  Stripe.publishableKey = TAPIs.stripePublishableKey;
  await Stripe.instance.applySettings();

  /// -- Initialize Firebase & Authentication Repository
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then((FirebaseApp value) {
  Get.lazyPut(() => LanguageController(), fenix: true);
  return Get.put(AuthenticationRepository());
  });

  /// -- Initialize RazorpayService
  Get.put(RazorpayService());


  /// -- Main App Starts here...
  runApp(const App());
}
