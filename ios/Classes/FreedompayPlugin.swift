import Flutter
import PayboxSdk
import UIKit

public class FreedompayPlugin: NSObject, FlutterPlugin {
  private var sdk: PayboxSdkProtocol?
  private weak var paymentView: PaymentView?
  private var overlayView: UIView?

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
      handleCreatePayment(call, result: result)
    case "createRecurringPayment":
      handleCreateRecurringPayment(call, result: result)
    case "createCardPayment":
      handleCreateCardPayment(call, result: result)
    case "payByCard":
      handlePayByCard(call, result: result)
    case "getPaymentStatus":
      handleGetPaymentStatus(call, result: result)
    case "makeRevokePayment":
      handleMakeRevokePayment(call, result: result)
    case "makeClearingPayment":
      handleMakeClearingPayment(call, result: result)
    case "makeCancelPayment":
      handleMakeCancelPayment(call, result: result)
    case "addNewCard":
      handleAddNewCard(call, result: result)
    case "removeAddedCard":
      handleRemoveAddedCard(call, result: result)
    case "getAddedCards":
      handleGetAddedCards(call, result: result)
    case "createNonAcceptancePayment":
      handleCreateNonAcceptancePayment(call, result: result)
    case "createApplePayment":
      handleCreateApplePayment(call, result: result)
    case "confirmApplePayment":
      handleConfirmApplePayment(call, result: result)
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let merchantId = arguments["merchantId"] as? Int,
      let secretKey = arguments["secretKey"] as? String
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "merchantId and secretKey are required", details: nil))
      return
    }
    sdk = PayboxSdk.initialize(merchantId: merchantId, secretKey: secretKey)
    result(nil)
  }

  private func handleCreatePayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let amountValue = arguments["amount"] as? NSNumber,
          let description = arguments["description"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount and description are required", details: nil))
      return
    }
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    let orderId = arguments["orderId"] as? String
    let userId = arguments["userId"] as? String
    let extraParams = mapToStringDictionary(arguments["extraParams"])

    withPaymentView(result: result) { paymentView in
      sdk.setPaymentView(paymentView: paymentView)
      sdk.createPayment(
        amount: amountValue.floatValue,
        description: description,
        orderId: orderId,
        userId: userId,
        extraParams: extraParams
      ) { payment, error in
        self.deliver(
          result: result,
          payload: [
            "payment": self.mapFromPayment(payment),
            "error": self.mapFromError(error),
          ]
        )
      }
    }
  }

  private func handleCreateRecurringPayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let amountValue = arguments["amount"] as? NSNumber,
          let description = arguments["description"] as? String,
          let recurringProfile = arguments["recurringProfile"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount, description and recurringProfile are required", details: nil))
      return
    }
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    let orderId = arguments["orderId"] as? String
    let extraParams = mapToStringDictionary(arguments["extraParams"])

    sdk.createRecurringPayment(
      amount: amountValue.floatValue,
      description: description,
      recurringProfile: recurringProfile,
      orderId: orderId,
      extraParams: extraParams
    ) { recurring, error in
      self.deliver(
        result: result,
        payload: [
          "recurringPayment": self.mapFromRecurring(recurring),
          "error": self.mapFromError(error),
        ]
      )
    }
  }

  private func handleCreateCardPayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let amountValue = arguments["amount"] as? NSNumber,
          let description = arguments["description"] as? String,
          let orderId = arguments["orderId"] as? String,
          let userId = arguments["userId"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount, description, orderId and userId are required", details: nil))
      return
    }
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    let cardId = arguments["cardId"] as? NSNumber
    let cardToken = arguments["cardToken"] as? String
    let extraParams = mapToStringDictionary(arguments["extraParams"])

    if cardId == nil && (cardToken == nil || cardToken?.isEmpty == true) {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Either cardId or cardToken must be provided", details: nil))
      return
    }

    let completion: (Payment?, PayboxSdk.Error?) -> Void = { payment, error in
      self.deliver(
        result: result,
        payload: [
          "payment": self.mapFromPayment(payment),
          "error": self.mapFromError(error),
        ]
      )
    }

    if let cardToken = cardToken, !cardToken.isEmpty {
      sdk.createCardPayment(
        amount: amountValue.floatValue,
        userId: userId,
        cardToken: cardToken,
        description: description,
        orderId: orderId,
        extraParams: extraParams,
        payInited: completion
      )
    } else if let cardId = cardId {
      sdk.createCardPayment(
        amount: amountValue.floatValue,
        userId: userId,
        cardId: cardId.intValue,
        description: description,
        orderId: orderId,
        extraParams: extraParams,
        payInited: completion
      )
    }
  }

  private func handlePayByCard(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let paymentId = arguments["paymentId"] as? NSNumber else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentId is required", details: nil))
      return
    }
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    withPaymentView(result: result) { paymentView in
      sdk.setPaymentView(paymentView: paymentView)
      sdk.payByCard(paymentId: paymentId.intValue) { payment, error in
        self.deliver(
          result: result,
          payload: [
            "payment": self.mapFromPayment(payment),
            "error": self.mapFromError(error),
          ]
        )
      }
    }
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
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    sdk.getPaymentStatus(paymentId: paymentId.intValue) { status, error in
      self.deliver(
        result: result,
        payload: [
          "status": self.mapFromStatus(status),
          "error": self.mapFromError(error),
        ]
      )
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
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    sdk.makeRevokePayment(paymentId: paymentId.intValue, amount: amountValue.floatValue) { payment, error in
      self.deliver(
        result: result,
        payload: [
          "payment": self.mapFromPayment(payment),
          "error": self.mapFromError(error),
        ]
      )
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
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    let amountValue = (arguments["amount"] as? NSNumber)?.floatValue

    sdk.makeClearingPayment(paymentId: paymentId.intValue, amount: amountValue) { capture, error in
      self.deliver(
        result: result,
        payload: [
          "capture": self.mapFromCapture(capture),
          "error": self.mapFromError(error),
        ]
      )
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
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    sdk.makeCancelPayment(paymentId: paymentId.intValue) { payment, error in
      self.deliver(
        result: result,
        payload: [
          "payment": self.mapFromPayment(payment),
          "error": self.mapFromError(error),
        ]
      )
    }
  }

  private func handleAddNewCard(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let userId = arguments["userId"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "userId is required", details: nil))
      return
    }
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    let postLink = arguments["postLink"] as? String

    withPaymentView(result: result) { paymentView in
      sdk.setPaymentView(paymentView: paymentView)
      sdk.addNewCard(postLink: postLink, userId: userId) { payment, error in
        self.deliver(
          result: result,
          payload: [
            "payment": self.mapFromPayment(payment),
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
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    sdk.removeAddedCard(cardId: cardId.intValue, userId: userId) { card, error in
      self.deliver(
        result: result,
        payload: [
          "card": self.mapFromCard(card),
          "error": self.mapFromError(error),
        ]
      )
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
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    sdk.getAddedCards(userId: userId) { cards, error in
      let cardMaps = cards?.map { self.mapFromCard($0) ?? [:] }
      self.deliver(
        result: result,
        payload: [
          "cards": cardMaps,
          "error": self.mapFromError(error),
        ]
      )
    }
  }

  private func handleCreateNonAcceptancePayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let paymentId = (arguments["paymentId"] as? NSNumber)?.intValue else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentId is required", details: nil))
      return
    }
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    sdk.createNonAcceptancePayment(paymentId: paymentId) { payment, error in
      self.deliver(
        result: result,
        payload: [
          "payment": self.mapFromPayment(payment),
          "error": self.mapFromError(error),
        ]
      )
    }
  }

  private func handleCreateApplePayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let amountValue = arguments["amount"] as? NSNumber,
          let description = arguments["description"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount and description are required", details: nil))
      return
    }
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    let orderId = arguments["orderId"] as? String
    let userId = arguments["userId"] as? String
    let extraParams = mapToStringDictionary(arguments["extraParams"])

    sdk.createApplePayment(
      amount: amountValue.floatValue,
      description: description,
      orderId: orderId,
      userId: userId,
      extraParams: extraParams
    ) { paymentId, error in
      self.deliver(
        result: result,
        payload: [
          "paymentId": paymentId,
          "error": self.mapFromError(error),
        ]
      )
    }
  }

  private func handleConfirmApplePayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let paymentId = arguments["paymentId"] as? String,
          let tokenData = arguments["tokenData"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentId and tokenData are required", details: nil))
      return
    }
    guard let sdk = ensureSdk(result: result) else {
      return
    }
    sdk.confirmApplePayment(paymentId: paymentId, tokenData: tokenData.data) { payment, error in
      self.deliver(
        result: result,
        payload: [
          "payment": self.mapFromPayment(payment),
          "error": self.mapFromError(error),
        ]
      )
    }
  }

  private func ensureSdk(result: FlutterResult) -> PayboxSdkProtocol? {
    guard let sdk = sdk else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "Paybox SDK is not initialized", details: nil))
      return nil
    }
    return sdk
  }

  private func withPaymentView(result: @escaping FlutterResult, action: @escaping (PaymentView) -> Void) {
    DispatchQueue.main.async {
      guard let hostView = self.topViewController()?.view else {
        result(FlutterError(code: "NO_VIEW", message: "Unable to obtain host view", details: nil))
        return
      }
      self.dismissOverlay()
      let container = UIView(frame: hostView.bounds)
      container.backgroundColor = .white
      container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      let paymentView = PaymentView(frame: container.bounds)
      paymentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      container.addSubview(paymentView)
      hostView.addSubview(container)
      self.overlayView = container
      self.paymentView = paymentView
      action(paymentView)
    }
  }

  private func dismissOverlay() {
    if Thread.isMainThread {
      overlayView?.removeFromSuperview()
      overlayView = nil
      paymentView = nil
    } else {
      DispatchQueue.main.async {
        self.overlayView?.removeFromSuperview()
        self.overlayView = nil
        self.paymentView = nil
      }
    }
  }

  private func deliver(result: @escaping FlutterResult, payload: [String: Any?]) {
    DispatchQueue.main.async {
      self.dismissOverlay()
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

  private func mapFromPayment(_ payment: Payment?) -> [String: Any?]? {
    guard let payment = payment else { return nil }
    return [
      "status": payment.status,
      "paymentId": payment.paymentId,
      "merchantId": payment.merchantId,
      "orderId": payment.orderId,
      "redirectUrl": payment.redirectUrl,
    ]
  }

  private func mapFromRecurring(_ recurring: RecurringPayment?) -> [String: Any?]? {
    guard let recurring = recurring else { return nil }
    return [
      "status": recurring.status,
      "paymentId": recurring.paymentId,
      "currency": recurring.currency,
      "amount": recurring.amount,
      "recurringProfile": recurring.recurringProfile,
      "recurringExpireDate": recurring.recurringExpireDate,
    ]
  }

  private func mapFromStatus(_ status: Status?) -> [String: Any?]? {
    guard let status = status else { return nil }
    return [
      "status": status.status,
      "paymentId": status.paymentId,
      "transactionStatus": status.transactionStatus,
      "canReject": status.canReject,
      "isCaptured": status.isCaptured,
      "cardPan": status.cardPan,
      "createDate": status.createDate,
    ]
  }

  private func mapFromCapture(_ capture: Capture?) -> [String: Any?]? {
    guard let capture = capture else { return nil }
    return [
      "status": capture.status,
      "amount": capture.amount,
      "clearingAmount": capture.clearingAmount,
    ]
  }

  private func mapFromCard(_ card: Card?) -> [String: Any?]? {
    guard let card = card else { return nil }
    return [
      "status": card.status,
      "merchantId": card.merchantId,
      "cardId": card.cardId,
      "cardToken": card.cardToken,
      "recurringProfile": card.recurringProfile,
      "cardhash": card.cardhash,
      "date": card.date,
    ]
  }

  private func mapFromError(_ error: PayboxSdk.Error?) -> [String: Any?]? {
    guard let error = error else { return nil }
    return [
      "errorCode": error.errorCode,
      "description": error.description,
    ]
  }

  private func mapToStringDictionary(_ value: Any?) -> [String: String]? {
    guard let dictionary = value as? [String: Any] else { return nil }
    var mapped: [String: String] = [:]
    for (key, item) in dictionary {
      if !(item is NSNull) {
        mapped[key] = "\(item)"
      }
    }
    return mapped
  }

  private func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
    .compactMap { scene in
      (scene as? UIWindowScene)?.windows.first { $0.isKeyWindow }?.rootViewController
    }
    .first ?? UIApplication.shared.delegate?.window??.rootViewController) -> UIViewController? {
    if let nav = base as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(base: selected)
    }
    if let presented = base?.presentedViewController {
      return topViewController(base: presented)
    }
    return base
  }
}
