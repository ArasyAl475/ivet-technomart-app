import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';

import '../../../utils/constants/api_constants.dart';

class TMidtransPaymentService extends GetxController with WidgetsBindingObserver {
  static TMidtransPaymentService get instance =>
      Get.isRegistered<TMidtransPaymentService>() ? Get.find<TMidtransPaymentService>() : Get.put(TMidtransPaymentService(), permanent: true);

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  MidtransSDK? _midtrans;
  Completer<Map<String, dynamic>>? _paymentCompleter;
  String? _currentOrderId;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initSDK();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("🔔 App Lifecycle Changed: $state");
    // If app comes to foreground, force a DB check
    if (state == AppLifecycleState.resumed) {
      _verifyPaymentStatusOnServer();
    }
  }

  /// -----------------------------------------------------------
  /// THE CRITICAL DB CHECKER
  /// -----------------------------------------------------------
  Future<void> _verifyPaymentStatusOnServer() async {
    // If we already finished this transaction, don't check again.
    if (_paymentCompleter == null || _paymentCompleter!.isCompleted || _currentOrderId == null) return;

    print("⏳ Checking Database for Payment Update...");

    // Small delay to let Cloud Function finish writing
    await Future.delayed(const Duration(seconds: 2));

    try {
      // 1. Check Firestore 'Orders' collection
      final doc = await FirebaseFirestore.instance.collection('Orders').doc(_currentOrderId).get();

      String? status;

      if (doc.exists) {
        final data = doc.data();
        status = data?['paymentStatus']?.toString().toLowerCase();
        print("🔍 Database Status found: $status");

        // 2. ACCEPT 'paid', 'succeeded', 'settlement', OR 'pending' as success navigation
        if (status == 'paid' || status == 'succeeded' || status == 'settlement' || status == 'pending') {
          _completePayment({
            'paymentStatus': 'Succeeded',
            'paymentMethod': 'midtrans',
          });
          return;
        }
      }

      // If we are here, DB says unpaid/failed.
      // BUT: If the SDK callback hasn't fired "Failed" yet, we keep waiting (don't fail yet).
      // We only explicitly fail if we are sure.
      print("⚠️ Database says $status. Waiting for user action or further updates.");
    } catch (e) {
      print("Error checking status: $e");
    }
  }

  Future<void> _initSDK() async {
    _midtrans = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: TAPIs.midtransClientKey,
        merchantBaseUrl: "https://us-central1-ivet-technomart.cloudfunctions.net/",
        colorTheme: ColorTheme(
          colorPrimary: Get.theme.primaryColor,
          colorPrimaryDark: Get.theme.primaryColorDark,
          colorSecondary: Get.theme.colorScheme.secondary,
        ),
      ),
    );

    _midtrans?.setTransactionFinishedCallback((dynamic result) {
      print("✅ SDK Callback Triggered: $result");
      _handleTransactionResult(result);
    });
  }

  /// -----------------------------------------------------------
  /// HANDLE SDK RESULT (THE FIX)
  /// -----------------------------------------------------------
  void _handleTransactionResult(dynamic result) {
    if (_paymentCompleter == null || _paymentCompleter!.isCompleted) return;

    bool isCancelled = false;
    try {
      isCancelled = result.status == 'canceled';
    } catch (_) {
      try {
        isCancelled = result['status'] == 'canceled';
      } catch (__) {}
    }

    // CRITICAL FIX: If SDK says Cancelled, DO NOT FAIL IMMEDIATELY.
    // Check the database first! The user might have paid and then closed the app.
    if (isCancelled) {
      print("⚠️ SDK says Cancelled. Verifying with Database before failing...");
      // _verifyPaymentStatusOnServer();

      // If after checking DB it is still not paid, THEN we fail (after a short delay)
      Future.delayed(const Duration(seconds: 3), () {
        if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
          _completePayment({'paymentStatus': 'Failed', 'errorMessage': 'Payment Cancelled'});
        }
      });
      return;
    }

    // If SDK says success directly
    _completePayment({
      'paymentStatus': 'Succeeded',
      'paymentMethod': 'midtrans',
    });
  }

  void _completePayment(Map<String, dynamic> result) {
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(result);
      // _paymentCompleter = null;
      _currentOrderId = null;
    }
  }

  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String orderId,
    required String userEmail,
    required String userName,
    required String userPhone,
  }) async {
    try {
      if (_midtrans == null) await _initSDK();

      _currentOrderId = orderId;
      _paymentCompleter = Completer<Map<String, dynamic>>();

      final String snapToken = await _getSnapToken(
        amount: amount,
        orderId: orderId,
        email: userEmail,
        name: userName,
        phone: userPhone,
      ).timeout(const Duration(seconds: 15));

      _midtrans?.setTransactionFinishedCallback((dynamic result) {
        _handleTransactionResult(result);
      });

      _midtrans?.startPaymentUiFlow(token: snapToken);

      return await _paymentCompleter!.future;
    } catch (e) {
      _paymentCompleter = null;
      _currentOrderId = null;
      return {
        'paymentStatus': 'Failed',
        'errorMessage': e.toString(),
      };
    }
  }

  Future<String> _getSnapToken({
    required double amount,
    required String orderId,
    required String email,
    required String name,
    required String phone,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('createMidtransTransaction');
    final result = await callable.call(<String, dynamic>{
      'amount': amount,
      'orderId': orderId,
      'userDetails': {'email': email, 'name': name, 'phone': phone}
    });
    return result.data['snapToken'] as String;
  }
}
