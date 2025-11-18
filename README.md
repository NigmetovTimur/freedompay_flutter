# Freedompay Flutter SDK

Плагин для Flutter, который инкапсулирует работу c нативным Paybox/FreedomPay SDK на Android и iOS. Он упрощает инициализацию SDK, открытие платежных форм, создание и подтверждение платежей, управление сохранёнными картами и интеграцию с Apple Pay/Google Pay.

> **Примечание:** после миграции на FreedomPay Merchant/Payment SDK полный обзор всех доступных Flutter-методов (параметры, ожидаемые ответы и поддержка на Android/iOS) приведён в [docs/flutter_payment_flows.md](docs/flutter_payment_flows.md). Краткая русскоязычная инструкция с перечнем методов, параметров и форматов ответов находится в [docs/flutter_methods_ru.md](docs/flutter_methods_ru.md).

## Возможности

- Инициализация Paybox SDK по `merchantId` и `secretKey`.
- Создание обычных, рекуррентных и карточных платежей.
- Управление жизненным циклом платежа (клиринг, отмена, возврат, проверка статуса).
- Добавление, удаление и получение списка сохранённых карт клиента.
- Работа с платежами без акцепта и подтверждение платежей по готовому идентификатору.
- Интеграция с Apple Pay на iOS и Google Pay на Android.
- Отрисовка нативной формы оплаты поверх Flutter-приложения и управление жизненным циклом оверлея.

## Требования

- Flutter 3.x (null-safety).
- Android: требуется Activity контекст. Плагин сам подключает `PaymentView` из Paybox SDK и показывает его в полноэкранном оверлее.
- iOS: требуется конфигурация Paybox SDK и активное `UIViewController`. Google Pay на iOS не поддерживается (возвращается ошибка с кодом `-1`).
- Получите значения `merchantId` и `secretKey` в личном кабинете FreedomPay.

## Установка

Добавьте плагин в `pubspec.yaml` проекта:

```yaml
dependencies:
  freedompay: ^1.0.0 # укажите актуальную версию
```

Выполните `flutter pub get` для загрузки зависимостей.

## Быстрый старт

```dart
import 'package:freedompay/freedompay.dart';

final freedompay = const Freedompay();

Future<void> pay() async {
  await freedompay.initialize(merchantId: 123456, secretKey: 'your-secret');

  final response = await freedompay.createPayment(
    amount: 1000.0,
    description: 'Оплата заказа #42',
    orderId: '42',
    userId: 'client-123',
  );

  final payment = response['payment'];
  final error = response['error'];

  if (error != null) {
    // error = {'errorCode': int, 'description': String}
    throw Exception('Платёж не создан: ${error['description']}');
  }

  // payment = {
  //   'status': String,
  //   'paymentId': int,
  //   'merchantId': int,
  //   'orderId': String?,
  //   'redirectUrl': String?
  // }

  // Если требуется, покажите redirectUrl в WebView или ожидайте web-хука.
}
```

Все методы возвращают `Future<Map<String, dynamic>>`. Каждая карта ответа содержит полезные данные операции и объект `error` (если ошибка пришла со стороны SDK/API). Когда поле отсутствует, приходит `null`.

## Структура данных и обмен с SDK

| Метод | Что отправляем | Что возвращается |
| --- | --- | --- |
| `initialize` | `merchantId` (int), `secretKey` (String). Данные уходят напрямую в Paybox SDK и не сохраняются в плагине. | `null` – успешная инициализация. Ошибки вернутся через `PlatformException`/`FlutterError`. |
| `createPayment` | Сумму (`amount`), описание (`description`), опционально `orderId`, `userId`, `extraParams`. Передаётся в Paybox SDK, который создаёт платёж и при необходимости инициирует редирект. | `payment`: `{status, paymentId, merchantId, orderId, redirectUrl}`, `error`: `{errorCode, description}`. |
| `createRecurringPayment` | `amount`, `description`, `recurringProfile`, опционально `orderId`, `extraParams`. | `recurringPayment`: `{status, paymentId, currency, amount, recurringProfile, recurringExpireDate}`, `error`. |
| `createCardPayment` | `amount`, `description`, `orderId`, `userId`, + либо `cardToken`, либо `cardId`, опционально `extraParams`. | `payment`: как в `createPayment`, `error`. |
| `payByCard` | `paymentId` платежа, который нужно оплатить по ранее сохранённым данным. | `payment`, `error`. |
| `getPaymentStatus` | `paymentId`. | `status`: `{status, paymentId, transactionStatus, canReject, isCaptured, cardPan, createDate}`, `error`. |
| `makeRevokePayment` | `paymentId`, `amount` (сумма возврата). | `payment`, `error`. |
| `makeClearingPayment` | `paymentId`, опционально частичный `amount`. | `capture`: `{status, amount, clearingAmount}`, `error`. |
| `makeCancelPayment` | `paymentId`. | `payment`, `error`. |
| `addNewCard` | `userId`, опционально `postLink` для обратного редиректа. На Android/iOS открывается полноэкранный `PaymentView`, куда пользователь вводит данные карты. | `payment`, `error`. Успешный ответ содержит `paymentId` — идентификатор привязки карты. |
| `removeAddedCard` | `cardId`, `userId`. | `card`: `{status, merchantId, cardId, cardToken, recurringProfile, cardhash, date}`, `error`. |
| `getAddedCards` | `userId`. | `cards`: список карт в формате, как в `removeAddedCard`, `error`. |
| `createNonAcceptancePayment` | `paymentId` существующего платежа. | `payment`, `error`. |
| `createGooglePayment` *(Android)* | `amount`, `description`, опционально `orderId`, `userId`, `extraParams`. | `paymentId`, `error`. На iOS вернётся `error` с описанием «Google Pay is not supported on iOS». |
| `confirmGooglePayment` *(Android)* | `paymentId` (String), `token` из Google Pay. | `payment`, `error`. На iOS вернётся ошибка, как описано выше. |
| `createApplePayment` *(iOS)* | `amount`, `description`, опционально `orderId`, `userId`, `extraParams`. | `paymentId`, `error`. На Android метод пока не реализован. |
| `confirmApplePayment` *(iOS)* | `paymentId` (String), `tokenData` (`Uint8List`) из `PKPaymentToken.paymentData`. | `payment`, `error`. |

### Настройка `userConfiguration`

Контактные данные клиента передаются через `UserConfiguration` и автоматически пробрасываются в SDK. Устанавливайте каждое поле отдельным методом, при необходимости передавая `null` или вовсе не вызывая метод:

- `setUserPhone({phone: String?})` – отображает номер на платёжной странице;
- `setUserContactEmail({email: String?})` – контактный email клиента;
- `setUserEmail({email: String?})` – email пользователя для платёжной формы.

Также можно работать с конфигурацией напрямую:

- `SdkConfiguration` принимает два блока настроек: `userConfiguration` (контакты клиента) и `operationalConfiguration` (общие параметры SDK).
- `UserConfiguration` содержит `userPhone`, `userContactEmail`, `userEmail`. Если телефон или email заданы, SDK автоматически подставит их на платёжной странице вместо запроса у пользователя.
- `OperationalConfiguration` позволяет задать `testingMode`, `language`, `lifetime`, `autoClearing`, `checkUrl`, `resultUrl` и `requestMethod` (`GET/POST`). `null`-значения наследуют параметры мерчанта.

Пример настройки в Android-проекте (на базе официальной документации FreedomPay):

```kotlin
val myUserConfig = UserConfiguration(
    userPhone = "1234567890",
    userEmail = "user@example.com"
)

val myOperationalConfig = OperationalConfiguration(
    testingMode = false,
    language = Language.EN,
    lifetime = 600,
    autoClearing = true,
    resultUrl = "https://example.com/result",
    requestMethod = HttpMethod.POST
)

val sdkConfiguration = SdkConfiguration(
    userConfiguration = myUserConfig,
    operationalConfiguration = myOperationalConfig
)

freedomApi.setConfiguration(sdkConfiguration)
```

> **Важно:** все ответы отправляются с нативной стороны на основной поток. Плагин самостоятельно убирает оверлей платежной формы после завершения операции. Если нужная операция требует UI, обязательно вызывайте её, когда плагин привязан к активити/контроллеру (например, после `WidgetsBinding.instance.addPostFrameCallback`).

## Обработка ошибок

- Неверные аргументы возвращают `error` с кодом `INVALID_ARGUMENTS` либо `FlutterError`/`PlatformException`.
- Если SDK не успели проинициализировать, метод вернёт `error` с кодом `NOT_INITIALIZED`.
- На Android при отсутствии активити (`NO_ACTIVITY`) или неполучении `PaymentView` операция завершится ошибкой.
- На iOS ошибки `NO_VIEW`/`PayboxSdk.Error` приходят в том же поле `error`.

Всегда проверяйте наличие `response['error']` и обрабатывайте его прежде чем использовать данные успешного ответа.

## Типовой сценарий оплаты

1. Вызвать `initialize` сразу после старта приложения.
2. Создать платёж через `createPayment` или `createCardPayment`.
3. Если требуется, отобразить встроенную форму (например, `addNewCard` или `payByCard` сами показывают нативную форму ввода).
4. После возврата ответа проверить поле `error`.
5. Использовать `paymentId` для дальнейших операций (`getPaymentStatus`, `makeClearingPayment`, `makeRevokePayment`, `makeCancelPayment`).
6. Для Google Pay/Apple Pay: сначала создать платёж, затем отправить токен через `confirmGooglePayment` или `confirmApplePayment`.

## Работа с сохранёнными картами

- Чтобы привязать карту, вызывайте `addNewCard`. Пользователь введёт данные карты в нативной форме, после чего вы получите `paymentId` и связанные параметры.
- Для последующих платежей вызывайте `createCardPayment`, передавая `cardToken` или `cardId`.
- Чтобы удалить карту, используйте `removeAddedCard`.
- Список карт клиента можно получить через `getAddedCards`.

## Защита данных

- `merchantId` и `secretKey` никогда не логируются плагином и передаются только в Paybox SDK.
- Данные клиента (`amount`, `description`, `orderId`, `userId`, `extraParams`) уходят напрямую в Paybox API через нативный SDK. Плагин не кеширует их.
- Обратные ответы содержат только параметры, которые предоставляет Paybox SDK: идентификаторы платежей, статусы, ошибки, сведения о привязанных картах (без полного PAN, только маску `cardPan`/`cardhash`).
- Для Apple Pay/Google Pay передаются только предоставленные этими сервисами токены (`tokenData`, `token`), которые Paybox SDK отправляет на сервера FreedomPay.

## Отладка

- Логи Paybox SDK выводятся в системные логи платформы (Logcat / Xcode). Используйте их для диагностики.
- При интеграции рекомендуется оборачивать все вызовы в `try/catch`, чтобы ловить `PlatformException`.
- Проверяйте сетевые настройки и whitelists, если редирект или загрузка формы не происходят.

Теперь README содержит всю необходимую информацию, чтобы быстро подключить и правильно использовать плагин Freedompay во Flutter-приложении.
