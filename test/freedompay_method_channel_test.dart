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
}
