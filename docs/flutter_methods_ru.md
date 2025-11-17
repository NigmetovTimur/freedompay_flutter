# Инструкция по методам Flutter-плагина FreedomPay

Документ перечисляет все публичные методы класса `Freedompay` из `lib/freedompay.dart`, их назначение, параметры и формат ответов. Поведение описано с учётом миграции на новые SDK: Merchant SDK (Android) и Payment SDK (iOS). Структура Dart API не менялась, поэтому названия методов и ключи в ответах совпадают с прежними.

## Общие принципы
- Все методы возвращают `Future<Map<String, dynamic>>` (кроме `initialize`, который возвращает `Future<void>`).
- В ответе обычно присутствуют два ключа: полезные данные (`payment`, `status`, `capture`, `cards` и т.п.) и `error`.
- Ошибка представлена картой `{ errorCode: string/int, description: string }`. Если ошибки нет, значение `error` равно `null`.
- Регион в нативном коде по умолчанию `KZ`. Переключение региона сейчас не вынесено в Dart API.

## Инициализация
### `initialize({ required int merchantId, required String secretKey })`
- Назначение: создать экземпляр `FreedomAPI` на обеих платформах.
- Параметры: идентификатор мерчанта и секретный ключ.
- Ответ: `null` при успехе, либо `PlatformException` при неверных аргументах.

### `setUserConfiguration({ String? userPhone, String? userEmail })`
- Назначение: передать контактные данные клиента в нативный SDK через `UserConfiguration` (используйте вместо `extraParams`).
- Параметры: телефон и/или email клиента. Можно указать один или оба значения.
- Ответ: `null` при успешном обновлении конфигурации либо `PlatformException` при отсутствии обоих параметров.

## Создание платёжной страницы
### `createPayment({ required double amount, required String description, String? orderId, String? userId, Map<String, String>? extraParams })`
- Назначение: открыть платёжную веб-страницу/фрейм.
- Android: собирает `StandardPaymentRequest` и открывает `PaymentView`; результат `{ payment, error }`, где `payment` включает `status`, `paymentId`, `merchantId`, `orderId`, `redirectUrl: null`.
- iOS: новый Payment SDK не поддерживает веб-страницу; возвращается `error` с кодом `UNSUPPORTED`.

## Рекуррентный платёж
### `createRecurringPayment({ required double amount, required String description, required String recurringProfile, String? orderId, Map<String, String>? extraParams })`
- Назначение: исторически — автосписание по профилю.
- Android/iOS: новые SDK прямого аналога не имеют; метод возвращает `recurringPayment: null` и `error` с кодом `UNSUPPORTED`.

## Оплата сохранённой картой (токен)
### `createCardPayment({ required double amount, required String description, required String orderId, required String userId, int? cardId, String? cardToken, Map<String, String>? extraParams })`
- Назначение: сформировать платёж по токену карты.
- Android: используется только `cardToken`; `cardId` игнорируется. Ответ `{ payment, error }` из `createCardPayment` Merchant SDK.
- iOS: Payment SDK не предоставляет прямого метода; возвращается `error` `UNSUPPORTED`.

### `payByCard({ required int paymentId })`
- Назначение: подтвердить платеж, созданный через `createCardPayment`.
- Android: вызывает `confirmCardPayment`; ответ `{ payment, error }`.
- iOS: не поддерживается, возвращает `error` `UNSUPPORTED`.

## Статус платежа
### `getPaymentStatus({ required int paymentId })`
- Назначение: получить актуальное состояние транзакции.
- Android: `getPaymentStatus(paymentId, includeLastTransactionInfo: null)` → `{ status, error }`, где `status` повторяет поля SDK (`paymentId`, `transactionStatus`, `amount`, `paymentMethod`, `canReject`, др.).
- iOS: `status` содержит `status`, `paymentId`, `transactionStatus`, `canReject`, `isCaptured`, `cardPan`, `createDate`.

## Клиринг (capture)
### `makeClearingPayment({ required int paymentId, double? amount })`
- Назначение: провести клиринг/захват суммы после авторизации.
- Android: `makeClearingPayment` → `{ capture, error }`, `capture.status` соответствует `ClearingStatus` SDK.
- iOS: аналогичный ответ, статус мапится на `success|failed|exceedsPaymentAmount`.

## Возврат (revoke/refund)
### `makeRevokePayment({ required int paymentId, required double amount })`
- Назначение: полный или частичный возврат.
- Android/iOS: `makeRevokePayment` → `{ payment, error }` с полями `status`, `paymentId`, `amount`, `transactionStatus` и др.

## Отмена (void)
### `makeCancelPayment({ required int paymentId })`
- Назначение: отменить платёж до клиринга.
- Android/iOS: `makeCancelPayment` → `{ payment, error }`.

## Безакцепт/подтверждение без страницы
### `createNonAcceptancePayment({ required int paymentId })`
- Назначение: старый безакцептный сценарий.
- Android: вызывает `confirmDirectPayment` → `{ payment, error }`.
- iOS: не поддерживается, возвращает `error` `UNSUPPORTED`.

## Управление картами
### `addNewCard({ required String userId, String? postLink })`
- Назначение: добавить новую карту пользователю.
- Android: открывает `PaymentView` для добавления; ответ `{ payment, error }`, `cardId` — плейсхолдер (SDK отдаёт токен). Возвращённый `postLink` не используется SDK напрямую.
- iOS: не поддерживается, возвращает `error` `UNSUPPORTED`.

### `getAddedCards({ required String userId })`
- Назначение: получить список карт.
- Android: `getAddedCards` → `{ cards, error }`, где `cards` — список карт с `cardId` (плейсхолдером), `cardNumber`, `cardType`.
- iOS: аналогичный ответ `cards`, берутся из Payment SDK.

### `removeAddedCard({ required int cardId, required String userId })`
- Назначение: удалить сохранённую карту.
- Android: `removeAddedCard` → `{ payment, error }`, в новых SDK `cardId` конвертируется в строковый токен-плейсхолдер.
- iOS: `removeAddedCard` поддерживается и возвращает `{ payment, error }`.

## Google Pay (Android)
### `createGooglePayment({ required double amount, required String description, String? orderId, String? userId, Map<String, String>? extraParams })`
- Назначение: подготовить платёж для Google Pay, чтобы получить `paymentId`.
- Android: собирает `StandardPaymentRequest` → `{ paymentId, error }`. Требуется передать токен из Google Pay в следующем методе.
- iOS: возвращает `error` `UNSUPPORTED`.

### `confirmGooglePayment({ required String paymentId, required String token })`
- Назначение: подтвердить Google Pay платёж токеном из кошелька.
- Android: `confirmGooglePayment` Merchant SDK → `{ payment, error }`.
- iOS: `error` `UNSUPPORTED`.

## Apple Pay (iOS)
### `createApplePayment({ required double amount, required String description, String? orderId, String? userId, Map<String, String>? extraParams })`
### `confirmApplePayment({ required String paymentId, required Uint8List tokenData })`
- Назначение: исторический Apple Pay флоу старого SDK.
- Android: оба метода возвращают `error` `UNSUPPORTED`.
- iOS: текущий Payment SDK не предоставляет готовый Apple Pay флоу; методы возвращают `error` `UNSUPPORTED`. Для Apple Pay требуется сторонняя интеграция с передачей токенов через сервер и дальнейшее использование других API SDK (не входит в плагин).

## Обработка ошибок
- Android: ошибки `FreedomResult.Error` переводятся в карту `{ errorCode: <Validation|Network|Infrastructure|Webview|Transaction>, description }`.
- iOS: `FreedomError` мапится на числовой `errorCode` и текст `description`.
- Если SDK не поддерживает сценарий, плагин возвращает `errorCode: UNSUPPORTED` и описание.
