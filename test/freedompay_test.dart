import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:freedompay/freedompay.dart';
import 'package:freedompay/freedompay_platform_interface.dart';
import 'package:freedompay/freedompay_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFreedompayPlatform extends FreedompayPlatform
    with MockPlatformInterfaceMixin {
  int? initializedMerchantId;
  String? initializedSecretKey;

  @override
  Future<void> initialize({
    required int merchantId,
    required String secretKey,
  }) async {
    initializedMerchantId = merchantId;
    initializedSecretKey = secretKey;
  }

  @override
  Future<Map<String, dynamic>> createApplePayment({
    required double amount,
    required String description,
    String? orderId,
    String? userId,
    Map<String, String>? extraParams,
  }) async {
    return <String, dynamic>{'paymentId': 'apple-payment-id', 'error': null};
  }

  @override
  Future<Map<String, dynamic>> confirmApplePayment({
    required String paymentId,
    required Uint8List tokenData,
  }) async {
    return <String, dynamic>{
      'payment': <String, dynamic>{'paymentId': paymentId, 'status': 'Success'},
      'error': null,
    };
  }
}

void main() {
  final FreedompayPlatform initialPlatform = FreedompayPlatform.instance;

  test('$MethodChannelFreedompay is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFreedompay>());
  });

  test('initialize delegates to the active platform implementation', () async {
    Freedompay freedompayPlugin = Freedompay();
    MockFreedompayPlatform fakePlatform = MockFreedompayPlatform();
    FreedompayPlatform.instance = fakePlatform;

    await freedompayPlugin.initialize(
      merchantId: 123456,
      secretKey: 'secret-key',
    );

    expect(fakePlatform.initializedMerchantId, 123456);
    expect(fakePlatform.initializedSecretKey, 'secret-key');
  });

  test('createApplePayment returns the platform payload', () async {
    Freedompay freedompayPlugin = Freedompay();
    MockFreedompayPlatform fakePlatform = MockFreedompayPlatform();
    FreedompayPlatform.instance = fakePlatform;

    final response = await freedompayPlugin.createApplePayment(
      amount: 1000,
      description: 'Order #42',
      orderId: '42',
      userId: 'user-1',
    );

    expect(response['paymentId'], 'apple-payment-id');
    expect(response['error'], isNull);
  });
}
