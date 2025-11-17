
import 'dart:typed_data';

import 'freedompay_platform_interface.dart';

class Freedompay {
  const Freedompay();

  FreedompayPlatform get _platform => FreedompayPlatform.instance;

  Future<void> initialize({required int merchantId, required String secretKey}) {
    return _platform.initialize(merchantId: merchantId, secretKey: secretKey);
  }

  Future<void> setResultUrl({required String url}) {
    return _platform.setResultUrl(url: url);
  }

  Future<void> setCheckUrl({required String url}) {
    return _platform.setCheckUrl(url: url);
  }

  Future<void> setUserConfiguration({String? userPhone, String? userEmail}) {
    return _platform.setUserConfiguration(
      userPhone: userPhone,
      userEmail: userEmail,
    );
  }

  Future<Map<String, dynamic>> createPayment({
    required double amount,
    required String description,
    String? orderId,
    String? userId,
    Map<String, String>? extraParams,
  }) {
    return _platform.createPayment(
      amount: amount,
      description: description,
      orderId: orderId,
      userId: userId,
      extraParams: extraParams,
    );
  }

  Future<Map<String, dynamic>> createRecurringPayment({
    required double amount,
    required String description,
    required String recurringProfile,
    String? orderId,
    Map<String, String>? extraParams,
  }) {
    return _platform.createRecurringPayment(
      amount: amount,
      description: description,
      recurringProfile: recurringProfile,
      orderId: orderId,
      extraParams: extraParams,
    );
  }

  Future<Map<String, dynamic>> createCardPayment({
    required double amount,
    required String description,
    required String orderId,
    required String userId,
    int? cardId,
    String? cardToken,
    Map<String, String>? extraParams,
  }) {
    return _platform.createCardPayment(
      amount: amount,
      description: description,
      orderId: orderId,
      userId: userId,
      cardId: cardId,
      cardToken: cardToken,
      extraParams: extraParams,
    );
  }

  Future<Map<String, dynamic>> payByCard({required int paymentId}) {
    return _platform.payByCard(paymentId: paymentId);
  }

  Future<Map<String, dynamic>> getPaymentStatus({required int paymentId}) {
    return _platform.getPaymentStatus(paymentId: paymentId);
  }

  Future<Map<String, dynamic>> makeRevokePayment({
    required int paymentId,
    required double amount,
  }) {
    return _platform.makeRevokePayment(paymentId: paymentId, amount: amount);
  }

  Future<Map<String, dynamic>> makeClearingPayment({
    required int paymentId,
    double? amount,
  }) {
    return _platform.makeClearingPayment(paymentId: paymentId, amount: amount);
  }

  Future<Map<String, dynamic>> makeCancelPayment({required int paymentId}) {
    return _platform.makeCancelPayment(paymentId: paymentId);
  }

  Future<Map<String, dynamic>> addNewCard({
    required String userId,
    String? postLink,
  }) {
    return _platform.addNewCard(userId: userId, postLink: postLink);
  }

  Future<Map<String, dynamic>> removeAddedCard({
    required int cardId,
    required String userId,
  }) {
    return _platform.removeAddedCard(cardId: cardId, userId: userId);
  }

  Future<Map<String, dynamic>> getAddedCards({required String userId}) {
    return _platform.getAddedCards(userId: userId);
  }

  Future<Map<String, dynamic>> createNonAcceptancePayment({required int paymentId}) {
    return _platform.createNonAcceptancePayment(paymentId: paymentId);
  }

  Future<Map<String, dynamic>> createGooglePayment({
    required double amount,
    required String description,
    String? orderId,
    String? userId,
    Map<String, String>? extraParams,
  }) {
    return _platform.createGooglePayment(
      amount: amount,
      description: description,
      orderId: orderId,
      userId: userId,
      extraParams: extraParams,
    );
  }

  Future<Map<String, dynamic>> confirmGooglePayment({
    required String paymentId,
    required String token,
  }) {
    return _platform.confirmGooglePayment(paymentId: paymentId, token: token);
  }

  Future<Map<String, dynamic>> createApplePayment({
    required double amount,
    required String description,
    String? orderId,
    String? userId,
    Map<String, String>? extraParams,
  }) {
    return _platform.createApplePayment(
      amount: amount,
      description: description,
      orderId: orderId,
      userId: userId,
      extraParams: extraParams,
    );
  }

  Future<Map<String, dynamic>> confirmApplePayment({
    required String paymentId,
    required Uint8List tokenData,
  }) {
    return _platform.confirmApplePayment(
      paymentId: paymentId,
      tokenData: tokenData,
    );
  }
}
