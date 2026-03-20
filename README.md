# FreedomPay Flutter SDK

Flutter-плагин для работы с нативными FreedomPay SDK на Android и iOS.

## Что внутри

- инициализация SDK через `merchantId` и `secretKey`
- создание платёжной страницы и `payment frame`
- карточные платежи, статусы, клиринг, отмена, возврат
- привязка и удаление карт
- Google Pay на Android
- Apple Pay на iOS

## Документация

- Канонический manual по публичному Flutter API: [docs/sdk_manual_ru.md](docs/sdk_manual_ru.md)
- Android зависимости и требования: [docs/android-dependencies.md](docs/android-dependencies.md)

## Быстрый старт

```dart
import 'package:freedompay/freedompay.dart';

final freedompay = const Freedompay();

Future<void> pay() async {
  await freedompay.initialize(
    merchantId: 123456,
    secretKey: 'your-secret',
  );

  final result = await freedompay.createPayment(
    amount: 1000,
    description: 'Order #42',
    orderId: '42',
    userId: 'user-1',
  );

  if (result['error'] != null) {
    throw Exception(result['error']['description']);
  }
}
```

## Платформенные требования

- Android: `minSdk 28`
- iOS: `15.0+`
- Для методов с UI плагин должен быть привязан к активному `Activity` / `UIViewController`

## Важно

- `createRecurringPayment` сохранён только для совместимости и возвращает `UNSUPPORTED`.
- `createGooglePayment` / `confirmGooglePayment` работают только на Android.
- `createApplePayment` / `confirmApplePayment` работают только на iOS.
- Для операций с сохранёнными картами используйте `cardToken`; `cardId` оставлен как legacy fallback.
