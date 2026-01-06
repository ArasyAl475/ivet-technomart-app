import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tstore_ecommerce_app/features/personalization/models/user_model.dart';

import '../../../features/authentication/screens/onboarding/onboarding.dart';
import '../../../features/authentication/screens/signup/verify_email.dart';
import '../../../features/authentication/screens/welcome/welcome_screen.dart';
import '../../../features/personalization/controllers/user_controller.dart';
import '../../../home_menu.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_auth_exceptions.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../../../utils/local_storage/storage_utility.dart';
import '../../../utils/popups/loaders.dart';
import '../user/user_repository.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  final deviceStorage = GetStorage();
  late final Rx<User?> _firebaseUser;
  var phoneNo = ''.obs;
  var phoneNoVerificationId = ''.obs;
  var isPhoneAutoVerified = false;
  final _auth = FirebaseAuth.instance;
  int? _resendToken;

  /// Getters
  User? get firebaseUser => _firebaseUser.value;

  String get getUserID => _firebaseUser.value?.uid ?? "";

  String get getUserEmail => _firebaseUser.value?.email ?? "";

  String get getDisplayName => _firebaseUser.value?.displayName ?? "";

  String get getPhoneNo => _firebaseUser.value?.phoneNumber ?? "";

  bool get isUserLoggedIn => _firebaseUser.value != null;

  bool get isGuestUser => deviceStorage.read('isGuestMode') ?? false;

  /// Called from main.dart on app launch
  @override
  void onReady() {
    _firebaseUser = Rx<User?>(_auth.currentUser);
    _firebaseUser.bindStream(_auth.userChanges());
    FlutterNativeSplash.remove();
    screenRedirect();
  }

  /// Function to Show Relevant Screen
  Future<void> screenRedirect() async {
    // Check if user is logged in via Firebase
    if (isUserLoggedIn) {
      final user = _firebaseUser.value!; // We know user is not null here
      // If a user is logged in, they are not a guest, so ensure guest mode is false
      await deviceStorage.write('isGuestMode', false);

      // Fetch User Record
      await UserController.instance.fetchUserRecord();

      // Use this to check auth Role for admin
      final idTokenResult = await user.getIdTokenResult();

      // If email verified let the user go to Home Screen else to the Email Verification Screen
      if (user.emailVerified || user.phoneNumber != null || idTokenResult.claims?['admin'] == true) {
        // Initialize User Specific Storage
        await TLocalStorage.init(user.uid);
        Get.offAll(() => const HomeMenu());
      } else {
        Get.offAll(() => VerifyEmailScreen(email: getUserEmail));
      }
    }else {
      // User is not logged in via Firebase. Check if they chose guest mode.
      // if (isGuestUser) {
      //   // User is in Guest Mode, navigate to HomeMenu
      //   Get.offAll(() => const HomeMenu());
      // } else {
        // User is not logged in and not a guest.
        // This is for new users or users who have logged out and not chosen guest mode.
        deviceStorage.writeIfNull('isFirstTime', true);
        // If it's their first time, show OnBoarding, otherwise WelcomeScreen.
        bool isFirstTime = deviceStorage.read('isFirstTime') ?? true;
        if (isFirstTime) {
          Get.offAll(() => const OnBoardingScreen());
        } else {
          Get.offAll(() => const WelcomeScreen());
        }
      // }
    }
  }

  /* ---------------------------- Email & Password sign-in ---------------------------------*/

  /// [EmailAuthentication] - SignIn
  Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      // After successful login, ensure guest mode is off
      await deviceStorage.write('isGuestMode', false);
      // screenRedirect will handle the rest based on the logged-in user
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWrongTryAgain.tr;
    }
  }

  /// [EmailAuthentication] - REGISTER
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // After successful registration, ensure guest mode is off
      await deviceStorage.write('isGuestMode', false);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWrongTryAgain.tr;
    }
  }

  /// [ReAuthenticate] - ReAuthenticate User
  Future<void> reAuthenticateWithEmailAndPassword(String email, String password) async {
    try {
      // Create a credential
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);

      // ReAuthenticate
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWrongTryAgain.tr;
    }
  }

  /// [EmailVerification] - MAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWrongTryAgain.tr;
    }
  }

  /// [EmailAuthentication] - FORGET PASSWORD
  Future<void> sendPasswordResetEmail(email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWrongTryAgain.tr;
    }
  }

  /* ---------------------------- Federated identity & social sign-in ---------------------------------*/

  /// [GoogleAuthentication] - GOOGLE
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth?.accessToken, idToken: googleAuth?.idToken);

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential); // Assuming 'credential' is obtained
      if (userCredential.user != null) {
        await deviceStorage.write('isGuestMode', false);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      if (kDebugMode) print('Something went wrong: $e');
      return null;
    }
  }

  /* ---------------------------- Phone Number sign-in ---------------------------------*/

  /// [PhoneAuthentication] - LOGIN - Register
  Future<void> loginWithPhoneNo(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: _resendToken,
        timeout: const Duration(minutes: 2),
        verificationFailed: (e) async {
          print('loginWithPhoneNo: verificationFailed => $e');
          await FirebaseCrashlytics.instance.recordError(e, e.stackTrace);

          if (e.code == 'too-many-requests') {
            Get.offAllNamed(TRoutes.welcome);
            TLoaders.warningSnackBar(title: TTexts.tooManyAttempts.tr, message:TTexts.tooManyAttemptsMessage.tr);
            return;
          } else if (e.code == 'unknown') {
            Get.back(result: false);
            TLoaders.warningSnackBar(title:TTexts.smaNotSent.tr, message: TTexts.smaNotSentMessage.tr);
            return;
          }
          TLoaders.warningSnackBar(title: TTexts.ohSnap.tr, message: e.message ?? '');
        },
        codeSent: (verificationId, resendToken) {
          print('--------------- codeSent');
          phoneNoVerificationId.value = verificationId;
          _resendToken = resendToken;
          print('--------------- codeSent: $verificationId');
        },
        verificationCompleted: (credential) async {
          print('--------------- verificationCompleted');
          var signedInUser = await _auth.signInWithCredential(credential);
          isPhoneAutoVerified = signedInUser.user != null;

          await screenRedirect();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // phoneNoVerificationId.value = verificationId;
          print('--------------- codeAutoRetrievalTimeout: $verificationId');
        },
      );
      phoneNo.value = phoneNumber;
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWrongTryAgain.tr;
    }
  }

  /// [PhoneAuthentication] - VERIFY PHONE NO BY OTP
  Future<bool> verifyOTP(String otp, String phoneNumber) async {
    try {
      final phoneCredentials = PhoneAuthProvider.credential(verificationId: phoneNoVerificationId.value, smsCode: otp);
      var credentials = await _auth.signInWithCredential(phoneCredentials);
      if (credentials.user != null) {
        await deviceStorage.write('isGuestMode', false);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, e.stackTrace);
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWrongTryAgain.tr;
    } finally {
      phoneNo.value = '';
      phoneNoVerificationId.value = '';
      isPhoneAutoVerified = false;
    }
  }

  /* ---------------------------- ./end Federated identity & social sign-in ---------------------------------*/

  /// [LogoutUser] - Valid for any authentication.
  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      UserController.instance.user.value = UserModel.empty();
      _firebaseUser.value = null;
      await deviceStorage.write('isGuestMode', true);
      await deviceStorage.write('isFirstTime', false);
      screenRedirect();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWrongTryAgain.tr;
    }
  }

  /// DELETE USER - Remove user Auth and Firestore Account.
  Future<void> deleteAccount() async {
    try {
      await UserRepository.instance.removeUserRecord(_auth.currentUser!.uid);
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWrongTryAgain.tr;
    }
  }

  /// Show a reusable "Sign In Required" popup for guest users.
  /// [message] can be customized based on the action (default provided).
  void showSignInRequiredPopup({String? message}) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign In Required'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message ?? 'You need to sign in to continue using this feature.'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 50),
            ),
            onPressed: () {
              Get.back();
              Get.toNamed(TRoutes.welcome);
            },
            child: Text('Sign In'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
