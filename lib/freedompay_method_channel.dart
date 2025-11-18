import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'freedompay_platform_interface.dart';

/// An implementation of [FreedompayPlatform] that uses method channels.
class MethodChannelFreedompay extends FreedompayPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('freedompay');

  Future<Map<String, dynamic>> _invokeMap(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      method,
      arguments,
    );
    return map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
  }

  @override
  Future<void> initialize({required int merchantId, required String secretKey}) {
    return methodChannel.invokeMethod<void>('initialize', <String, dynamic>{
      'merchantId': merchantId,
      'secretKey': secretKey,
    });
  }

  @override
  Future<void> setResultUrl({required String url}) {
    return methodChannel.invokeMethod<void>('setResultUrl', <String, dynamic>{
      'url': url,
    });
  }

  @override
  Future<void> setCheckUrl({required String url}) {
    return methodChannel.invokeMethod<void>('setCheckUrl', <String, dynamic>{
      'url': url,
    });
  }

  @override
  Future<Map<String, dynamic>> createPayment({
    required double amount,
    required String description,
    String? orderId,
    String? userId,
    Map<String, String>? extraParams,
  }) {
    return _invokeMap('createPayment', <String, dynamic>{
      'amount': amount,
      'description': description,
      if (orderId != null) 'orderId': orderId,
      if (userId != null) 'userId': userId,
      if (extraParams != null) 'extraParams': extraParams,
    });
  }

  @override
  Future<Map<String, dynamic>> createRecurringPayment({
    required double amount,
    required String description,
    required String recurringProfile,
    String? orderId,
    Map<String, String>? extraParams,
  }) {
    return _invokeMap('createRecurringPayment', <String, dynamic>{
      'amount': amount,
      'description': description,
      'recurringProfile': recurringProfile,
      if (orderId != null) 'orderId': orderId,
      if (extraParams != null) 'extraParams': extraParams,
    });
  }

  @override
  Future<Map<String, dynamic>> createCardPayment({
    required double amount,
    required String description,
    required String orderId,
    required String userId,
    int? cardId,
    String? cardToken,
    Map<String, String>? extraParams,
  }) {
    return _invokeMap('createCardPayment', <String, dynamic>{
      'amount': amount,
      'description': description,
      'orderId': orderId,
      'userId': userId,
      if (cardId != null) 'cardId': cardId,
      if (cardToken != null) 'cardToken': cardToken,
      if (extraParams != null) 'extraParams': extraParams,
    });
  }

  @override
  Future<Map<String, dynamic>> payByCard({required int paymentId}) {
    return _invokeMap('payByCard', <String, dynamic>{'paymentId': paymentId});
  }

  @override
  Future<Map<String, dynamic>> getPaymentStatus({required int paymentId}) {
    return _invokeMap('getPaymentStatus', <String, dynamic>{'paymentId': paymentId});
  }

  @override
  Future<Map<String, dynamic>> makeRevokePayment({
    required int paymentId,
    required double amount,
  }) {
    return _invokeMap('makeRevokePayment', <String, dynamic>{
      'paymentId': paymentId,
      'amount': amount,
    });
  }

  @override
  Future<Map<String, dynamic>> makeClearingPayment({
    required int paymentId,
    double? amount,
  }) {
    return _invokeMap('makeClearingPayment', <String, dynamic>{
      'paymentId': paymentId,
      if (amount != null) 'amount': amount,
    });
  }

  @override
  Future<Map<String, dynamic>> makeCancelPayment({required int paymentId}) {
    return _invokeMap('makeCancelPayment', <String, dynamic>{'paymentId': paymentId});
  }

  @override
  Future<Map<String, dynamic>> addNewCard({
    required String userId,
    String? postLink,
  }) {
    return _invokeMap('addNewCard', <String, dynamic>{
      'userId': userId,
      if (postLink != null) 'postLink': postLink,
    });
  }

  @override
  Future<Map<String, dynamic>> removeAddedCard({
    required int cardId,
    required String userId,
  }) {
    return _invokeMap('removeAddedCard', <String, dynamic>{
      'cardId': cardId,
      'userId': userId,
    });
  }

  @override
  Future<Map<String, dynamic>> getAddedCards({required String userId}) {
    return _invokeMap('getAddedCards', <String, dynamic>{'userId': userId});
  }

  @override
  Future<Map<String, dynamic>> createNonAcceptancePayment({required int paymentId}) {
    return _invokeMap('createNonAcceptancePayment', <String, dynamic>{
      'paymentId': paymentId,
    });
  }

  @override
  Future<Map<String, dynamic>> createGooglePayment({
    required double amount,
    required String description,
    String? orderId,
    String? userId,
    Map<String, String>? extraParams,
  }) {
    return _invokeMap('createGooglePayment', <String, dynamic>{
      'amount': amount,
      'description': description,
      if (orderId != null) 'orderId': orderId,
      if (userId != null) 'userId': userId,
      if (extraParams != null) 'extraParams': extraParams,
    });
  }

  @override
  Future<Map<String, dynamic>> confirmGooglePayment({
    required String paymentId,
    required String token,
  }) {
    return _invokeMap('confirmGooglePayment', <String, dynamic>{
      'paymentId': paymentId,
      'token': token,
    });
  }

  @override
  Future<Map<String, dynamic>> createApplePayment({
    required double amount,
    required String description,
    String? orderId,
    String? userId,
    Map<String, String>? extraParams,
  }) {
    return _invokeMap('createApplePayment', <String, dynamic>{
      'amount': amount,
      'description': description,
      if (orderId != null) 'orderId': orderId,
      if (userId != null) 'userId': userId,
      if (extraParams != null) 'extraParams': extraParams,
    });
  }

  @override
  Future<Map<String, dynamic>> confirmApplePayment({
    required String paymentId,
    required Uint8List tokenData,
  }) {
    return _invokeMap('confirmApplePayment', <String, dynamic>{
      'paymentId': paymentId,
      'tokenData': tokenData,
    });
  }
}
