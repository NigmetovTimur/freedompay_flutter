import Flutter
import FreedomPaymentSdk
import UIKit

// MIGRATED: old PayBox SDK -> new FreedomPay Payment SDK
public class FreedompayPlugin: NSObject, FlutterPlugin {
  private var freedomApi: FreedomAPI?
  private var sdkConfiguration = SdkConfiguration()
  private var checkUrl: String?
  private var resultUrl: String?
  private var userConfiguration = UserConfiguration()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "freedompay", binaryMessenger: registrar.messenger())
    let instance = FreedompayPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      handleInitialize(call, result: result)
    case "createPayment":
      notSupported(method: call.method, result: result)
    case "createRecurringPayment":
      notSupported(method: call.method, result: result)
    case "createCardPayment":
      notSupported(method: call.method, result: result)
    case "payByCard":
      notSupported(method: call.method, result: result)
    case "getPaymentStatus":
      handleGetPaymentStatus(call, result: result)
    case "makeRevokePayment":
      handleMakeRevokePayment(call, result: result)
    case "makeClearingPayment":
      handleMakeClearingPayment(call, result: result)
    case "makeCancelPayment":
      handleMakeCancelPayment(call, result: result)
    case "addNewCard":
      notSupported(method: call.method, result: result)
    case "removeAddedCard":
      handleRemoveAddedCard(call, result: result)
    case "getAddedCards":
      handleGetAddedCards(call, result: result)
    case "createNonAcceptancePayment":
      notSupported(method: call.method, result: result)
    case "createApplePayment":
      notSupported(method: call.method, result: result)
    case "confirmApplePayment":
      notSupported(method: call.method, result: result)
    case "createGooglePayment":
      result([
        "error": [
          "errorCode": -1,
          "description": "Google Pay is not supported on iOS",
        ],
      ])
    case "confirmGooglePayment":
      result([
        "error": [
          "errorCode": -1,
          "description": "Google Pay is not supported on iOS",
        ],
      ])
    case "setResultUrl":
      handleSetResultUrl(call, result: result)
    case "setCheckUrl":
      handleSetCheckUrl(call, result: result)
    case "setUserPhone":
      handleSetUserPhone(call, result: result)
    case "setUserContactEmail":
      handleSetUserContactEmail(call, result: result)
    case "setUserEmail":
      handleSetUserEmail(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let merchantIdNumber = arguments["merchantId"] as? NSNumber,
      let secretKey = arguments["secretKey"] as? String
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "merchantId and secretKey are required", details: nil))
      return
    }

    let region: Region = .kz
    let merchantId = merchantIdNumber.stringValue
    let api = FreedomAPI.create(merchantId: merchantId, secretKey: secretKey, region: region)
    api.setConfiguration(sdkConfiguration)
    freedomApi = api
    result(nil)
  }

  private func handleSetResultUrl(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let url = arguments["url"] as? String,
      !url.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "url is required", details: nil))
      return
    }

    resultUrl = url
    applyConfiguration()
    result(nil)
  }

  private func handleSetCheckUrl(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let url = arguments["url"] as? String,
      !url.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "url is required", details: nil))
      return
    }

    checkUrl = url
    applyConfiguration()
    result(nil)
  }

  private func handleSetUserPhone(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let phone = arguments["phone"] as? String,
      !phone.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "phone is required", details: nil))
      return
    }

    userConfiguration = UserConfiguration(
      userPhone: phone,
      userContactEmail: userConfiguration.userContactEmail,
      userEmail: userConfiguration.userEmail
    )
    applyConfiguration()
    result(nil)
  }

  private func handleSetUserContactEmail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let email = arguments["email"] as? String,
      !email.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "email is required", details: nil))
      return
    }

    userConfiguration = UserConfiguration(
      userPhone: userConfiguration.userPhone,
      userContactEmail: email,
      userEmail: userConfiguration.userEmail
    )
    applyConfiguration()
    result(nil)
  }

  private func handleSetUserEmail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let email = arguments["email"] as? String,
      !email.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "email is required", details: nil))
      return
    }

    userConfiguration = UserConfiguration(
      userPhone: userConfiguration.userPhone,
      userContactEmail: userConfiguration.userContactEmail,
      userEmail: email
    )
    applyConfiguration()
    result(nil)
  }

  private func handleGetPaymentStatus(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let paymentId = arguments["paymentId"] as? NSNumber else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentId is required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    api.getPaymentStatus(paymentId.int64Value) { sdkResult in
      switch sdkResult {
      case let .success(status):
        self.deliver(
          result: result,
          payload: [
            "status": self.mapFromStatus(status),
            "error": NSNull(),
          ]
        )
      case let .error(error):
        self.deliver(
          result: result,
          payload: [
            "status": NSNull(),
            "error": self.mapFromError(error),
          ]
        )
      }
    }
  }

  private func handleMakeRevokePayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let paymentId = arguments["paymentId"] as? NSNumber,
          let amountValue = arguments["amount"] as? NSNumber else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentId and amount are required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    api.makeRevokePayment(paymentId.int64Value, amount: amountValue.decimalValue) { sdkResult in
      switch sdkResult {
      case let .success(response):
        self.deliver(
          result: result,
          payload: [
            "payment": self.mapFromPaymentResponse(response),
            "error": NSNull(),
          ]
        )
      case let .error(error):
        self.deliver(
          result: result,
          payload: [
            "payment": NSNull(),
            "error": self.mapFromError(error),
          ]
        )
      }
    }
  }

  private func handleMakeClearingPayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let paymentId = arguments["paymentId"] as? NSNumber else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentId is required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }
    let amountValue = (arguments["amount"] as? NSNumber)?.decimalValue

    api.makeClearingPayment(paymentId.int64Value, amount: amountValue) { sdkResult in
      switch sdkResult {
      case let .success(clearingStatus):
        self.deliver(
          result: result,
          payload: [
            "capture": self.mapFromClearingStatus(clearingStatus),
            "error": NSNull(),
          ]
        )
      case let .error(error):
        self.deliver(
          result: result,
          payload: [
            "capture": NSNull(),
            "error": self.mapFromError(error),
          ]
        )
      }
    }
  }

  private func handleMakeCancelPayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let paymentId = arguments["paymentId"] as? NSNumber else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentId is required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    api.makeCancelPayment(paymentId.int64Value) { sdkResult in
      switch sdkResult {
      case let .success(payment):
        self.deliver(
          result: result,
          payload: [
            "payment": self.mapFromPaymentResponse(payment),
            "error": NSNull(),
          ]
        )
      case let .error(error):
        self.deliver(
          result: result,
          payload: [
            "payment": NSNull(),
            "error": self.mapFromError(error),
          ]
        )
      }
    }
  }

  private func handleRemoveAddedCard(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let cardId = arguments["cardId"] as? NSNumber,
          let userId = arguments["userId"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "cardId and userId are required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    api.removeCard(userId, cardToken: cardId.stringValue) { sdkResult in
      switch sdkResult {
      case let .success(card):
        self.deliver(
          result: result,
          payload: [
            "card": self.mapFromRemovedCard(card),
            "error": NSNull(),
          ]
        )
      case let .error(error):
        self.deliver(
          result: result,
          payload: [
            "card": NSNull(),
            "error": self.mapFromError(error),
          ]
        )
      }
    }
  }

  private func handleGetAddedCards(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let userId = arguments["userId"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "userId is required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    api.getAddedCards(userId) { sdkResult in
      switch sdkResult {
      case let .success(cards):
        let cardMaps = cards.map { self.mapFromCard($0) ?? [:] }
        self.deliver(
          result: result,
          payload: [
            "cards": cardMaps,
            "error": NSNull(),
          ]
        )
      case let .error(error):
        self.deliver(
          result: result,
          payload: [
            "cards": NSNull(),
            "error": self.mapFromError(error),
          ]
        )
      }
    }
  }

  private func applyConfiguration() {
    let operationalConfiguration = OperationalConfiguration(checkUrl: checkUrl, resultUrl: resultUrl)
    sdkConfiguration = SdkConfiguration(
      userConfiguration: userConfiguration,
      operationalConfiguration: operationalConfiguration
    )
    freedomApi?.setConfiguration(sdkConfiguration)
  }

  private func notSupported(method: String, result: @escaping FlutterResult) {
    deliver(
      result: result,
      payload: [
        "error": [
          "errorCode": -1,
          "description": "\(method) is not supported by FreedomPaymentSdk",
        ],
      ]
    )
  }

  private func ensureApi(result: FlutterResult) -> FreedomAPI? {
    guard let api = freedomApi else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "FreedomPaymentSdk is not initialized", details: nil))
      return nil
    }
    return api
  }

  private func deliver(result: @escaping FlutterResult, payload: [String: Any?]) {
    DispatchQueue.main.async {
      result(self.cleanDictionary(payload))
    }
  }

  private func cleanDictionary(_ map: [String: Any?]) -> [String: Any] {
    var dictionary: [String: Any] = [:]
    for (key, value) in map {
      switch value {
      case let nested as [String: Any?]:
        dictionary[key] = cleanDictionary(nested)
      case let array as [[String: Any?]]:
        dictionary[key] = array.map { cleanDictionary($0) }
      case let concreteValue?:
        dictionary[key] = concreteValue
      default:
        dictionary[key] = NSNull()
      }
    }
    return dictionary
  }

  private func mapFromPaymentResponse(_ payment: PaymentResponse?) -> [String: Any?]? {
    guard let payment = payment else { return nil }
    return [
      "status": payment.status,
      "paymentId": payment.paymentId,
      "merchantId": payment.merchantId,
      "orderId": payment.orderId,
      "redirectUrl": NSNull(),
    ]
  }

  private func mapFromStatus(_ status: Status?) -> [String: Any?]? {
    guard let status = status else { return nil }
    let mirror = Mirror(reflecting: status)
    let statusValue: String? = extractValue(mirror: mirror, key: "status")
    let paymentId: Int64? = extractValue(mirror: mirror, key: "paymentId")
    let transactionStatus: String? = extractValue(mirror: mirror, key: "paymentStatus")
    let canReject: Bool? = extractValue(mirror: mirror, key: "canReject")
    let isCaptured: Bool? = extractValue(mirror: mirror, key: "captured")
    let cardPan: String? = extractValue(mirror: mirror, key: "cardPan")
    let createDate: String? = extractValue(mirror: mirror, key: "createDate")

    return [
      "status": statusValue,
      "paymentId": paymentId,
      "transactionStatus": transactionStatus,
      "canReject": canReject,
      "isCaptured": isCaptured,
      "cardPan": cardPan,
      "createDate": createDate,
    ]
  }

  private func mapFromClearingStatus(_ capture: ClearingStatus?) -> [String: Any?]? {
    guard let capture else { return nil }
    switch capture {
    case let .success(amount):
      let doubleAmount = NSDecimalNumber(decimal: amount).doubleValue
      return [
        "status": "success",
        "amount": doubleAmount,
        "clearingAmount": doubleAmount,
      ]
    case .exceedsPaymentAmount:
      return [
        "status": "exceedsPaymentAmount",
        "amount": NSNull(),
        "clearingAmount": NSNull(),
      ]
    case .failed:
      return [
        "status": "failed",
        "amount": NSNull(),
        "clearingAmount": NSNull(),
      ]
    }
  }

  private func mapFromCard(_ card: Card?) -> [String: Any?]? {
    guard let card = card else { return nil }
    return [
      "status": card.status,
      "merchantId": card.merchantId,
      "cardId": NSNull(),
      "cardToken": card.cardToken,
      "recurringProfile": card.recurringProfileId,
      "cardhash": card.cardHash,
      "date": card.createdAt,
    ]
  }

  private func mapFromRemovedCard(_ card: RemovedCard?) -> [String: Any?]? {
    guard let card else { return nil }
    return [
      "status": card.status,
      "merchantId": card.merchantId,
      "cardId": NSNull(),
      "cardToken": NSNull(),
      "recurringProfile": NSNull(),
      "cardhash": card.cardHash,
      "date": card.deletedAt,
    ]
  }

  private func mapFromError(_ error: FreedomError?) -> [String: Any?]? {
    guard let error = error else { return nil }

    switch error {
    case let .transaction(errorCode, errorDescription):
      return [
        "errorCode": errorCode,
        "description": errorDescription ?? "",
      ]
    case let .validationError(errors):
      let message = errors.map { $0.rawValue }.joined(separator: ", ")
      return [
        "errorCode": -2,
        "description": message,
      ]
    case .paymentInitializationFailed:
      return [
        "errorCode": -3,
        "description": "Payment initialization failed",
      ]
    case let .networkError(networkError):
      return [
        "errorCode": -4,
        "description": "Network error: \(networkError)",
      ]
    case let .infrastructureError(infraError):
      return [
        "errorCode": -5,
        "description": "Infrastructure error: \(infraError)",
      ]
    }
  }

  private func extractValue<T>(mirror: Mirror, key: String) -> T? {
    for child in mirror.children {
      if child.label == key {
        return child.value as? T
      }
    }
    return nil
  }
}
