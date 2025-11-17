import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'freedompay_method_channel.dart';

abstract class FreedompayPlatform extends PlatformInterface {
  /// Constructs a FreedompayPlatform.
  FreedompayPlatform() : super(token: _token);

  static final Object _token = Object();

  static FreedompayPlatform _instance = MethodChannelFreedompay();

  /// The default instance of [FreedompayPlatform] to use.
  ///
  /// Defaults to [MethodChannelFreedompay].
  static FreedompayPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FreedompayPlatform] when
  /// they register themselves.
  static set instance(FreedompayPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize({required int merchantId, required String secretKey}) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> setResultUrl({required String url}) {
    throw UnimplementedError('setResultUrl() has not been implemented.');
  }

  Future<void> setCheckUrl({required String url}) {
    throw UnimplementedError('setCheckUrl() has not been implemented.');
  }

  Future<Map<String, dynamic>> createPayment({
    required double amount,
    required String description,
    String? orderId,
    String? userId,
    Map<String, String>? extraParams,
  }) {
    throw UnimplementedError('createPayment() has not been implemented.');
  }

  Future<Map<String, dynamic>> createRecurringPayment({
    required double amount,
    required String description,
    required String recurringProfile,
    String? orderId,
    Map<String, String>? extraParams,
  }) {
    throw UnimplementedError('createRecurringPayment() has not been implemented.');
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
    throw UnimplementedError('createCardPayment() has not been implemented.');
  }

  Future<Map<String, dynamic>> payByCard({required int paymentId}) {
    throw UnimplementedError('payByCard() has not been implemented.');
  }

  Future<Map<String, dynamic>> getPaymentStatus({required int paymentId}) {
    throw UnimplementedError('getPaymentStatus() has not been implemented.');
  }

  Future<Map<String, dynamic>> makeRevokePayment({
    required int paymentId,
    required double amount,
  }) {
    throw UnimplementedError('makeRevokePayment() has not been implemented.');
  }

  Future<Map<String, dynamic>> makeClearingPayment({
    required int paymentId,
    double? amount,
  }) {
    throw UnimplementedError('makeClearingPayment() has not been implemented.');
  }

  Future<Map<String, dynamic>> makeCancelPayment({required int paymentId}) {
    throw UnimplementedError('makeCancelPayment() has not been implemented.');
  }

  Future<Map<String, dynamic>> addNewCard({
    required String userId,
    String? postLink,
  }) {
    throw UnimplementedError('addNewCard() has not been implemented.');
  }

  Future<Map<String, dynamic>> removeAddedCard({
    required int cardId,
    required String userId,
  }) {
    throw UnimplementedError('removeAddedCard() has not been implemented.');
  }

  Future<Map<String, dynamic>> getAddedCards({required String userId}) {
    throw UnimplementedError('getAddedCards() has not been implemented.');
  }

  Future<Map<String, dynamic>> createNonAcceptancePayment({required int paymentId}) {
    throw UnimplementedError('createNonAcceptancePayment() has not been implemented.');
  }

  Future<Map<String, dynamic>> createGooglePayment({
    required double amount,
    required String description,
    String? orderId,
    String? userId,
    Map<String, String>? extraParams,
  }) {
    throw UnimplementedError('createGooglePayment() has not been implemented.');
  }

  Future<Map<String, dynamic>> confirmGooglePayment({
    required String paymentId,
    required String token,
  }) {
    throw UnimplementedError('confirmGooglePayment() has not been implemented.');
  }

  Future<Map<String, dynamic>> createApplePayment({
    required double amount,
    required String description,
    String? orderId,
    String? userId,
    Map<String, String>? extraParams,
  }) {
    throw UnimplementedError('createApplePayment() has not been implemented.');
  }

  Future<Map<String, dynamic>> confirmApplePayment({
    required String paymentId,
    required Uint8List tokenData,
  }) {
    throw UnimplementedError('confirmApplePayment() has not been implemented.');
  }
}
