# FreedomPay Flutter SDK Manual

Актуальная спецификация публичного Flutter API пакета `freedompay`.
Документ описывает именно слой Flutter (`lib/freedompay.dart`) и его соответствие Android/iOS плагинам.

## Общие правила

- `initialize` возвращает `Future<void>`.
- Остальные методы возвращают `Future<Map<String, dynamic>>`.
- Почти каждый ответ содержит полезную нагрузку (`payment`, `status`, `capture`, `cards`, `card`, `paymentId`) и поле `error`.
- Если сценарий платформой не поддерживается, плагин не возвращает `notImplemented`, а отдаёт предсказуемый payload: основной ключ будет `null`, а `error.errorCode = "UNSUPPORTED"`.
- Регион в текущем Flutter wrapper зафиксирован как `KZ`.
- Android-плагин требует `minSdk 28`, iOS-плагин требует `iOS 15.0`.

## Матрица методов

| Метод | Android | iOS | Назначение |
| --- | --- | --- | --- |
| `initialize` | Да | Да | Создание `FreedomAPI` по `merchantId` и `secretKey`. |
| `setResultUrl` | Да | Да | URL для server callback результата оплаты. |
| `setCheckUrl` | Да | Да | URL для server callback проверки оплаты. |
| `setUserPhone` | Да | Да | Подстановка телефона пользователя в SDK. |
| `setUserContactEmail` | Да | Да | Контактный email пользователя. |
| `setUserEmail` | Да | Да | Email пользователя для платёжной формы. |
| `createPayment` | Да | Да | Полноценная платёжная страница. |
| `createPaymentFrame` | Да | Да | Платёжный flow через `createPaymentFrame`. |
| `createRecurringPayment` | Возвращает `UNSUPPORTED` | Возвращает `UNSUPPORTED` | Legacy-метод, прямого аналога в новых SDK нет. |
| `createCardPayment` | Да | Да | Создание платежа по токенизированной карте. |
| `payByCard` | Да | Да | Подтверждение `createCardPayment`, при необходимости с UI/3DS. |
| `getPaymentStatus` | Да | Да | Получение состояния платежа. |
| `makeRevokePayment` | Да | Да | Возврат средств. |
| `makeClearingPayment` | Да | Да | Клиринг / capture. |
| `makeCancelPayment` | Да | Да | Отмена авторизованного платежа до клиринга. |
| `addNewCard` | Да | Да | Привязка новой карты пользователю. |
| `getAddedCards` | Да | Да | Получение списка привязанных карт. |
| `removeAddedCard` | Да | Да | Удаление карты по `cardToken` или legacy `cardId`. |
| `createNonAcceptancePayment` | Да | Да | Подтверждение direct payment без отдельного card token flow. |
| `createGooglePayment` | Да | `UNSUPPORTED` | Подготовка Google Pay платежа. |
| `confirmGooglePayment` | Да | `UNSUPPORTED` | Подтверждение Google Pay токеном кошелька. |
| `createApplePayment` | `UNSUPPORTED` | Да | Подготовка Apple Pay платежа. |
| `confirmApplePayment` | `UNSUPPORTED` | Да | Подтверждение Apple Pay `tokenData`. |

## Инициализация и конфигурация

### `initialize({ required int merchantId, required String secretKey })`

- Создаёт нативный `FreedomAPI`.
- Вызывать до любых платёжных методов.
- При неверных аргументах вернётся `PlatformException` / `FlutterError`.

### `setResultUrl({ required String url })`
### `setCheckUrl({ required String url })`
### `setUserPhone({ String? phone })`
### `setUserContactEmail({ String? email })`
### `setUserEmail({ String? email })`

- Эти методы обновляют текущую нативную конфигурацию без повторной инициализации SDK.
- `null` в user-полях очищает ранее заданное значение.

## Платёжные методы

### `createPayment({ required double amount, required String description, String? orderId, String? userId, Map<String, String>? extraParams })`

- Открывает стандартную платёжную страницу SDK.
- На Android и iOS автоматически поднимается `PaymentView` поверх Flutter UI.
- Успех: `{ payment, error: null }`.

### `createPaymentFrame({ required double amount, required String description, String? orderId, String? userId, Map<String, String>? extraParams })`

- То же, что `createPayment`, но использует native `createPaymentFrame`.
- Формат ответа такой же: `{ payment, error }`.

### `createRecurringPayment({ required double amount, required String description, required String recurringProfile, String? orderId, Map<String, String>? extraParams })`

- Сохранён для обратной совместимости.
- На обеих платформах возвращает:

```dart
{
  'recurringPayment': null,
  'error': {
    'errorCode': 'UNSUPPORTED',
    'description': '...'
  }
}
```

### `createCardPayment({ required double amount, required String description, required String orderId, required String userId, int? cardId, String? cardToken, Map<String, String>? extraParams })`

- Создаёт платёж по сохранённой карте.
- Предпочтительно передавать `cardToken`.
- `cardId` оставлен только как legacy fallback.
- На Android новый SDK фактически работает по `cardToken`.

### `payByCard({ required int paymentId })`

- Подтверждает платёж, созданный через `createCardPayment`.
- На обеих платформах теперь поднимается `PaymentView`, если SDK нужно показать CVC/3DS.
- Ответ: `{ payment, error }`.

### `getPaymentStatus({ required int paymentId, bool? includeLastTransactionInfo })`

- Получает актуальный статус транзакции.
- `includeLastTransactionInfo` прокидывается в native SDK на обеих платформах.
- Ответ: `{ status, error }`.

### `makeRevokePayment({ required int paymentId, required double amount })`

- Полный или частичный возврат.
- Ответ: `{ payment, error }`.

### `makeClearingPayment({ required int paymentId, double? amount })`

- Клиринг / частичный capture.
- Ответ: `{ capture, error }`.
- `capture.status` нормализован к значениям:
  - `success`
  - `failed`
  - `exceedsPaymentAmount`

### `makeCancelPayment({ required int paymentId })`

- Void / отмена авторизованного платежа до клиринга.
- Ответ: `{ payment, error }`.

### `createNonAcceptancePayment({ required int paymentId })`

- Direct confirmation flow.
- Ответ: `{ payment, error }`.

## Управление картами

### `addNewCard({ required String userId, String? orderId, @Deprecated('Use orderId instead.') String? postLink })`

- Запускает flow привязки карты.
- На обеих платформах используется `PaymentView`.
- `orderId` пробрасывается в новые native SDK.
- `postLink` сохранён как legacy alias и используется только как fallback, если `orderId` не передан.
- Ответ: `{ payment, error }`.

### `getAddedCards({ required String userId })`

- Возвращает список токенизированных карт пользователя.
- Ответ: `{ cards, error }`.

### `removeAddedCard({ int? cardId, String? cardToken, required String userId })`

- Предпочтительно использовать `cardToken`.
- `cardId` оставлен для обратной совместимости и строкифицируется как fallback.
- Ответ: `{ card, error }`.

## Wallet flows

### `createGooglePayment({ required double amount, required String description, String? orderId, String? userId, Map<String, String>? extraParams })`
### `confirmGooglePayment({ required String paymentId, required String token })`

- Реализованы только на Android.
- На iOS оба метода возвращают `UNSUPPORTED`.

### `createApplePayment({ required double amount, required String description, String? orderId, String? userId, Map<String, String>? extraParams })`
### `confirmApplePayment({ required String paymentId, required Uint8List tokenData })`

- Реализованы только на iOS.
- На Android оба метода возвращают `UNSUPPORTED`.

## Форматы ответов

### `payment`

```dart
{
  'status': String,
  'paymentId': int,
  'merchantId': String|int,
  'orderId': String?,
  'redirectUrl': String?,
}
```

### `status`

```dart
{
  'status': String,
  'paymentId': int,
  'transactionStatus': String?,
  'canReject': bool?,
  'isCaptured': bool?,
  'cardName': String?,
  'cardPan': String?,
  'createDate': String?,
  'paymentMethod': String?,
  'clearingAmount': num?,
  'revokedAmount': num?,
  'refundAmount': num?,
  'reference': int?,
  'authCode': int?,
  'failureCode': String?,
  'failureDescription': String?,
  'revokedPayments': List<Map<String, dynamic>>?,
  'refundPayments': List<Map<String, dynamic>>?,
  'lastTransactionInfo': Map<String, dynamic>?,
  'currency': String,
  'amount': num,
  'orderId': String?,
}
```

### `capture`

```dart
{
  'status': 'success' | 'failed' | 'exceedsPaymentAmount',
  'amount': num?,
  'clearingAmount': num?,
}
```

### `card` / элемент `cards`

```dart
{
  'status': String?,
  'merchantId': String?,
  'cardId': null, // legacy placeholder
  'cardToken': String?,
  'recurringProfile': String?,
  'cardhash': String?,
  'date': String?,
}
```

## Формат ошибок

```dart
{
  'errorCode': String|int,
  'description': String,
  'details': String?, // опционально, в основном Android
}
```

- Android отдаёт строковые коды ошибок Merchant SDK.
- iOS отдаёт коды из `FreedomError`; для platform-unsupported сценариев используется строковый код `UNSUPPORTED`.

## Важные замечания

- `cardId` в новых нативных SDK больше не является полноценным идентификатором карты; рабочий путь для повторных операций по карте это `cardToken`.
- Для методов с UI (`createPayment`, `createPaymentFrame`, `payByCard`, `addNewCard`) плагин сам создаёт и убирает overlay с `PaymentView`.
- `Google Pay` и `Apple Pay` документированы как platform-specific методы и теперь присутствуют в обоих нативных плагинах хотя бы в виде предсказуемого `UNSUPPORTED` ответа.
- Flutter wrapper пока не выносит наружу весь расширенный native `SdkConfiguration` и не позволяет менять region из Dart.
