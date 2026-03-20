## 0.4.0

* Synchronize the public Flutter API with Android and iOS plugins: add `createPaymentFrame`, forward `includeLastTransactionInfo`, support `orderId` in `addNewCard`, and support `cardToken` in `removeAddedCard`.
* Fix Android `payByCard` to use `PaymentView` for CVC / 3DS flows and normalize unsupported wallet/recurring methods to a consistent `UNSUPPORTED` payload.
* Expand status payload mapping, add a dedicated SDK manual, remove duplicated legacy docs, and align the example app with the plugin's Android `minSdk 28` requirement.

## 0.3.0

* Enable the main payment flows on iOS by wiring the Swift plugin to the current FreedomPaymentSdk APIs, including `PaymentView`-based UI flows, card operations, direct confirmation, and Apple Pay methods.
* Normalize iOS payload serialization for Flutter method channels and refresh tests/example/docs to match the current plugin API.

## 0.1.8

* Add verbose Android logging around `createPayment` requests and responses, and include detailed error payloads for transaction failures.

## 0.0.2

* Fix Android build by depending on the PayBox SDK from JitPack.

## 0.0.1

* TODO: Describe initial release.
