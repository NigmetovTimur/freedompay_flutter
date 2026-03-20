import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedompay/freedompay_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFreedompay platform = MethodChannelFreedompay();
  const MethodChannel channel = MethodChannel('freedompay');
  late MethodCall lastMethodCall;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          lastMethodCall = methodCall;
          if (methodCall.method == 'createApplePayment') {
            return <String, dynamic>{
              'paymentId': 'apple-payment-id',
              'error': null,
            };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'initialize passes merchant credentials to the method channel',
    () async {
      await platform.initialize(merchantId: 123456, secretKey: 'secret-key');

      expect(lastMethodCall.method, 'initialize');
      expect(lastMethodCall.arguments, <String, dynamic>{
        'merchantId': 123456,
        'secretKey': 'secret-key',
      });
    },
  );

  test('createApplePayment returns the native payload', () async {
    final response = await platform.createApplePayment(
      amount: 1000,
      description: 'Order #42',
      orderId: '42',
      userId: 'user-1',
      extraParams: const {'source': 'test'},
    );

    expect(lastMethodCall.method, 'createApplePayment');
    expect(response, <String, dynamic>{
      'paymentId': 'apple-payment-id',
      'error': null,
    });
  });

  test(
    'createPaymentFrame sends the frame method with payment arguments',
    () async {
      await platform.createPaymentFrame(
        amount: 750,
        description: 'Frame order',
        orderId: 'frame-42',
        userId: 'user-2',
        extraParams: const {'flow': 'frame'},
      );

      expect(lastMethodCall.method, 'createPaymentFrame');
      expect(lastMethodCall.arguments, <String, dynamic>{
        'amount': 750.0,
        'description': 'Frame order',
        'orderId': 'frame-42',
        'userId': 'user-2',
        'extraParams': const {'flow': 'frame'},
      });
    },
  );

  test('getPaymentStatus passes includeLastTransactionInfo when set', () async {
    await platform.getPaymentStatus(
      paymentId: 99,
      includeLastTransactionInfo: true,
    );

    expect(lastMethodCall.method, 'getPaymentStatus');
    expect(lastMethodCall.arguments, <String, dynamic>{
      'paymentId': 99,
      'includeLastTransactionInfo': true,
    });
  });

  test(
    'addNewCard prefers orderId and keeps legacy postLink optional',
    () async {
      await platform.addNewCard(
        userId: 'user-3',
        orderId: 'card-bind-1',
        postLink: 'legacy-post-link',
      );

      expect(lastMethodCall.method, 'addNewCard');
      expect(lastMethodCall.arguments, <String, dynamic>{
        'userId': 'user-3',
        'orderId': 'card-bind-1',
        'postLink': 'legacy-post-link',
      });
    },
  );

  test('removeAddedCard can send cardToken instead of legacy cardId', () async {
    await platform.removeAddedCard(
      userId: 'user-4',
      cardToken: 'card-token-123',
    );

    expect(lastMethodCall.method, 'removeAddedCard');
    expect(lastMethodCall.arguments, <String, dynamic>{
      'userId': 'user-4',
      'cardToken': 'card-token-123',
    });
  });
}
