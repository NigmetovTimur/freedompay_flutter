# FreedomPay Flutter Plugin Payment Flows

This document describes how to invoke every public payment-related method that the Flutter package exposes and how those calls are handled on Android and iOS after the migration to the FreedomPay SDKs. Public Dart APIs remain unchanged; platform code adapts to the new SDKs under the hood.

## Initialization
Call `initialize` once before any other method:

```dart
await const Freedompay().initialize(
  merchantId: 12345,
  secretKey: 'your-secret',
);
```

- Android creates `FreedomAPI` with region `KZ` and applies an empty `SdkConfiguration`. Region is not part of the Dart API; change requires native edits.  
- iOS also constructs `FreedomAPI` with region `kz` and default `SdkConfiguration`.

## Standard payment page
```dart
final result = await const Freedompay().createPayment(
  amount: 1000,
  description: 'Order #42',
  orderId: '42',
  userId: 'user-1',
  extraParams: {'key': 'value'},
);
```
- Android builds `StandardPaymentRequest`, injects a `PaymentView` overlay, and calls `createPaymentPage`. The result map has keys `{payment, error}` where `payment` contains `status`, `paymentId`, `merchantId`, `orderId`, and `redirectUrl: null`.
- iOS currently returns `error` because the Payment SDK does not expose a web payment page API.

## Recurring payments
`createRecurringPayment` keeps its Dart signature but returns `{recurringPayment: null, error}` on Android and `error` on iOS because the new SDKs do not provide a direct equivalent.

## Tokenized card payments
```dart
final result = await const Freedompay().createCardPayment(
  amount: 1000,
  description: 'Tokenized charge',
  orderId: '42',
  userId: 'user-1',
  cardToken: 'token-from-backend',
  extraParams: {'key': 'value'},
);
```
- Android requires `cardToken` (legacy `cardId` is no longer accepted) and calls `createCardPayment`. Follow-up confirmation uses `payByCard(paymentId: ...)` which maps to `confirmCardPayment`.
- iOS reports `not supported` for both methods because direct card payments are not exposed by the Payment SDK.

## Payment status
```dart
final status = await const Freedompay().getPaymentStatus(paymentId: 123);
```
- Android uses `getPaymentStatus(paymentId, includeLastTransactionInfo: null)` and returns `{status, error}` where `status` holds the SDK `Status` fields (`paymentId`, `transactionStatus`, `canReject`, `paymentMethod`, `amount`, etc.).
- iOS maps `FreedomAPI.getPaymentStatus` into `{status, error}` with legacy field names (`status`, `paymentId`, `transactionStatus`, `canReject`, `isCaptured`, `cardPan`, `createDate`).

## Capture / clearing
```dart
final capture = await const Freedompay().makeClearingPayment(
  paymentId: 123,
  amount: 500, // optional
);
```
- Android calls `makeClearingPayment` and returns `{capture, error}`; `capture.status` reflects the SDK `ClearingStatus` values.
- iOS maps the `ClearingStatus` enum to `{status: success|failed|exceedsPaymentAmount, amount, clearingAmount}`.

## Refund / revoke
```dart
final refund = await const Freedompay().makeRevokePayment(
  paymentId: 123,
  amount: 100,
);
```
- Android routes to `makeRevokePayment` and returns `{payment, error}` with `PaymentResponse` fields.
- iOS uses `makeRevokePayment` from the Payment SDK and returns the same `{payment, error}` shape.

## Cancel / void
```dart
final cancel = await const Freedompay().makeCancelPayment(paymentId: 123);
```
- Android calls `makeCancelPayment` and returns `{payment, error}`.
- iOS calls the corresponding Payment SDK API and returns `{payment, error}`.

## Non-acceptance / direct confirmation
```dart
final result = await const Freedompay().createNonAcceptancePayment(paymentId: 123);
```
- Android maps to `confirmDirectPayment` and returns `{payment, error}`.
- iOS returns `not supported` because the Payment SDK lacks this flow.

## Card management
```dart
await const Freedompay().addNewCard(userId: 'user-1');
await const Freedompay().getAddedCards(userId: 'user-1');
await const Freedompay().removeAddedCard(cardId: 1, userId: 'user-1');
```
- Android opens a `PaymentView` for `addNewCard`, lists cards via `getAddedCards`, and removes cards with `removeAddedCard`. Card IDs are placeholders because the new SDK exposes tokens instead of numeric IDs.
- iOS supports listing and removing cards; `addNewCard` is not exposed by the Payment SDK and returns an `error`.

## Google Pay (Android only)
```dart
final creation = await const Freedompay().createGooglePayment(
  amount: 100,
  description: 'GPay order',
);
final confirmation = await const Freedompay().confirmGooglePayment(
  paymentId: creation['paymentId'],
  token: googlePayToken,
);
```
- `createGooglePayment` builds a `StandardPaymentRequest` and returns `{paymentId, error}`.
- `confirmGooglePayment` calls `confirmGooglePayment` with the token and returns `{payment, error}`.
- iOS explicitly returns an `error` for both methods.

## Apple Pay (iOS only)
`createApplePayment` and `confirmApplePayment` remain in the Dart API but currently return `error` on iOS (and Android) because the new SDK does not expose Apple Pay flows. Handle the error on the Flutter side or integrate Apple Pay directly in your app and pass card tokens into `createCardPayment` where applicable.

## Common error shape
All native calls return a map with the legacy keys. If a native error occurs, the payload contains an `error` map with:

- Android: `errorCode` and `description` derived from `FreedomResult.Error` (validation, network, infrastructure, WebView, transaction).
- iOS: numeric `errorCode` plus `description` mapped from `FreedomError` cases.

## Required runtime configuration in Flutter
Pass the same fields as before migration:

- `merchantId`, `secretKey` via `initialize`.
- `amount`, `description`, `orderId`, `userId`, optional `extraParams` for payment creation.
- Per-flow IDs/tokens: `paymentId`, `cardToken`, Google Pay token, etc.
- Callback URLs (`check`, `result`, `success`, `failure`) are not part of the Dart API; configure them server-side when creating payment sessions.

## Platform prerequisites
- Android: minSdk 28, compileSdk 36, Kotlin/Java 11, Merchant SDK pulled from JitPack via Gradle.
- iOS: minimum iOS 15.0, `FreedomPaymentSdk` pod with static frameworks, and `ENABLE_USER_SCRIPT_SANDBOXING = NO` when using Xcode 15+.
