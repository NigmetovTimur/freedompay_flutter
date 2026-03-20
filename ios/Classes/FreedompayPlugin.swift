import Flutter
import FreedomPaymentSdk
import Foundation
import UIKit

// MIGRATED: old PayBox SDK -> new FreedomPay Payment SDK
public class FreedompayPlugin: NSObject, FlutterPlugin {
  private var freedomApi: FreedomAPI?
  private var sdkConfiguration = SdkConfiguration()
  private var checkUrl: String?
  private var resultUrl: String?
  private var userPhone: String?
  private var userContactEmail: String?
  private var userEmail: String?
  private var overlayContainer: UIView?

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
    case "createPaymentFrame":
      handleCreatePaymentFrame(call, result: result)
    case "createRecurringPayment":
      result(
        unsupportedPayload(
          valueKey: "recurringPayment",
          message: "Recurring payments are not supported by FreedomPaymentSdk"
        )
      )
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
      result(
        unsupportedPayload(
          valueKey: "paymentId",
          message: "Google Pay is not supported on iOS"
        )
      )
    case "confirmGooglePayment":
      result(
        unsupportedPayload(
          valueKey: "payment",
          message: "Google Pay is not supported on iOS"
        )
      )
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

  private func handleCreatePayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let amountValue = arguments["amount"] as? NSNumber,
      let description = arguments["description"] as? String,
      !description.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount and description are required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    let request = StandardPaymentRequest(
      amount: amountValue.decimalValue,
      description: description,
      userId: arguments["userId"] as? String,
      orderId: arguments["orderId"] as? String,
      extraParams: mapExtraParams(arguments["extraParams"])
    )

    withPaymentView(result: result) { paymentView in
      api.setPaymentView(paymentView)
      api.createPaymentPage(paymentRequest: request) { sdkResult in
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
  }

  private func handleCreatePaymentFrame(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let amountValue = arguments["amount"] as? NSNumber,
      let description = arguments["description"] as? String,
      !description.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount and description are required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    let request = StandardPaymentRequest(
      amount: amountValue.decimalValue,
      description: description,
      userId: arguments["userId"] as? String,
      orderId: arguments["orderId"] as? String,
      extraParams: mapExtraParams(arguments["extraParams"])
    )

    withPaymentView(result: result) { paymentView in
      api.setPaymentView(paymentView)
      api.createPaymentFrame(paymentRequest: request) { sdkResult in
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
    let arguments = call.arguments as? [String: Any]
    let phone = arguments?["phone"] as? String

    userPhone = phone
    applyConfiguration()
    result(nil)
  }

  private func handleSetUserContactEmail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    let email = arguments?["email"] as? String

    userContactEmail = email
    applyConfiguration()
    result(nil)
  }

  private func handleSetUserEmail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    let email = arguments?["email"] as? String

    userEmail = email
    applyConfiguration()
    result(nil)
  }

  private func handleCreateCardPayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let amountValue = arguments["amount"] as? NSNumber,
      let description = arguments["description"] as? String,
      !description.isEmpty,
      let orderId = arguments["orderId"] as? String,
      !orderId.isEmpty,
      let userId = arguments["userId"] as? String,
      !userId.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount, description, orderId and userId are required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    let cardToken = (arguments["cardToken"] as? String).flatMap { $0.isEmpty ? nil : $0 }
      ?? (arguments["cardId"] as? NSNumber)?.stringValue
    guard let cardToken else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "cardToken is required for the iOS SDK", details: nil))
      return
    }

    let request = TokenizedPaymentRequest(
      amount: amountValue.decimalValue,
      currency: nil,
      description: description,
      cardToken: cardToken,
      userId: userId,
      orderId: orderId,
      extraParams: mapExtraParams(arguments["extraParams"])
    )

    api.createCardPayment(request) { sdkResult in
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

  private func handlePayByCard(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let paymentId = arguments["paymentId"] as? NSNumber
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentId is required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    withPaymentView(result: result) { paymentView in
      api.setPaymentView(paymentView)
      api.confirmCardPayment(paymentId.int64Value) { sdkResult in
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

    let includeLastTransactionInfo = arguments["includeLastTransactionInfo"] as? Bool

    api.getPaymentStatus(paymentId.int64Value, includeLastTransactionInfo: includeLastTransactionInfo) { sdkResult in
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

  private func handleAddNewCard(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let userId = arguments["userId"] as? String,
      !userId.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "userId is required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }
    let orderId = (arguments["orderId"] as? String)?.nonEmpty
      ?? (arguments["postLink"] as? String)?.nonEmpty

    withPaymentView(result: result) { paymentView in
      api.setPaymentView(paymentView)
      api.addNewCard(userId: userId, orderId: orderId) { sdkResult in
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
  }

  private func handleRemoveAddedCard(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard let userId = arguments["userId"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "userId is required", details: nil))
      return
    }
    let cardToken = (arguments["cardToken"] as? String)?.nonEmpty
      ?? (arguments["cardId"] as? NSNumber)?.stringValue
    guard let cardToken else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "cardToken (or legacy cardId) is required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    api.removeCard(userId, cardToken: cardToken) { sdkResult in
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

  private func handleCreateNonAcceptancePayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let paymentId = arguments["paymentId"] as? NSNumber
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentId is required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    withPaymentView(result: result) { paymentView in
      api.setPaymentView(paymentView)
      api.confirmDirectPayment(paymentId.int64Value) { sdkResult in
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
  }

  private func handleCreateApplePayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let amountValue = arguments["amount"] as? NSNumber,
      let description = arguments["description"] as? String,
      !description.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "amount and description are required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    let request = StandardPaymentRequest(
      amount: amountValue.decimalValue,
      description: description,
      userId: arguments["userId"] as? String,
      orderId: arguments["orderId"] as? String,
      extraParams: mapExtraParams(arguments["extraParams"])
    )

    api.createApplePayment(paymentRequest: request) { sdkResult in
      switch sdkResult {
      case let .success(applePayment):
        self.deliver(
          result: result,
          payload: [
            "paymentId": applePayment.paymentId,
            "error": NSNull(),
          ]
        )
      case let .error(error):
        self.deliver(
          result: result,
          payload: [
            "paymentId": NSNull(),
            "error": self.mapFromError(error),
          ]
        )
      }
    }
  }

  private func handleConfirmApplePayment(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
      return
    }
    guard
      let paymentId = arguments["paymentId"] as? String,
      !paymentId.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "paymentId is required", details: nil))
      return
    }

    let tokenData: Data?
    if let typedData = arguments["tokenData"] as? FlutterStandardTypedData {
      tokenData = typedData.data
    } else {
      tokenData = arguments["tokenData"] as? Data
    }
    guard let tokenData else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "tokenData is required", details: nil))
      return
    }
    guard let api = ensureApi(result: result) else {
      return
    }

    api.confirmApplePayment(paymentId: paymentId, tokenData: tokenData) { sdkResult in
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

  private func applyConfiguration() {
    let operationalConfiguration = OperationalConfiguration(checkUrl: checkUrl, resultUrl: resultUrl)
    let userConfiguration = UserConfiguration(
      userPhone: userPhone,
      userContactEmail: userContactEmail,
      userEmail: userEmail
    )
    sdkConfiguration = SdkConfiguration(
      userConfiguration: userConfiguration,
      operationalConfiguration: operationalConfiguration
    )
    freedomApi?.setConfiguration(sdkConfiguration)
  }

  private func unsupportedPayload(valueKey: String, message: String) -> [String: Any] {
    cleanDictionary([
      valueKey: NSNull(),
      "error": unsupportedError(message),
    ])
  }

  private func unsupportedError(_ message: String) -> [String: Any?] {
    [
      "errorCode": "UNSUPPORTED",
      "description": message,
    ]
  }

  private func ensureApi(result: FlutterResult) -> FreedomAPI? {
    guard let api = freedomApi else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "FreedomPaymentSdk is not initialized", details: nil))
      return nil
    }
    return api
  }

  private func withPaymentView(result: @escaping FlutterResult, action: @escaping (PaymentView) -> Void) {
    DispatchQueue.main.async {
      guard let hostView = self.resolveHostView() else {
        result(FlutterError(code: "NO_VIEW", message: "Unable to resolve a host view for PaymentView", details: nil))
        return
      }

      self.dismissOverlay()

      let container = UIView(frame: hostView.bounds)
      container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      container.backgroundColor = .white

      let paymentView = PaymentView()
      paymentView.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(paymentView)
      NSLayoutConstraint.activate([
        paymentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        paymentView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        paymentView.topAnchor.constraint(equalTo: container.topAnchor),
        paymentView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      ])

      hostView.addSubview(container)
      self.overlayContainer = container
      action(paymentView)
    }
  }

  private func resolveHostView() -> UIView? {
    let windowScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
    let window = windowScenes
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
      ?? windowScenes.flatMap(\.windows).first(where: { !$0.isHidden })

    if let topController = resolveTopViewController(from: window?.rootViewController) {
      return topController.view
    }
    return window
  }

  private func resolveTopViewController(from controller: UIViewController?) -> UIViewController? {
    if let navigationController = controller as? UINavigationController {
      return resolveTopViewController(from: navigationController.visibleViewController)
    }
    if let tabBarController = controller as? UITabBarController {
      return resolveTopViewController(from: tabBarController.selectedViewController)
    }
    if let presented = controller?.presentedViewController {
      return resolveTopViewController(from: presented)
    }
    return controller
  }

  private func dismissOverlay() {
    DispatchQueue.main.async {
      self.overlayContainer?.removeFromSuperview()
      self.overlayContainer = nil
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

  private func mapFromPaymentResponse(_ payment: PaymentResponse?) -> [String: Any?]? {
    guard let payment = payment else { return nil }
    return [
      "status": mapFromPaymentStatus(payment.status),
      "paymentId": payment.paymentId,
      "merchantId": payment.merchantId,
      "orderId": payment.orderId,
      "redirectUrl": NSNull(),
    ]
  }

  private func mapFromStatus(_ status: Status?) -> [String: Any?]? {
    guard let status = status else { return nil }
    return [
      "status": status.status,
      "paymentId": status.paymentId,
      "transactionStatus": status.paymentStatus,
      "canReject": status.canReject,
      "isCaptured": status.captured,
      "cardName": status.cardName,
      "cardPan": status.cardPan,
      "createDate": status.createDate,
      "paymentMethod": status.paymentMethod,
      "clearingAmount": status.clearingAmount.map(decimalToDouble),
      "revokedAmount": status.revokedAmount.map(decimalToDouble),
      "refundAmount": status.refundAmount.map(decimalToDouble),
      "reference": status.reference,
      "authCode": status.authCode,
      "currency": status.currency,
      "amount": decimalToDouble(status.amount),
      "orderId": status.orderId,
      "failureCode": status.failureCode,
      "failureDescription": status.failureDescription,
      "revokedPayments": status.revokedPayments?.map(mapFromRevokedPayment),
      "refundPayments": status.refundPayments?.map(mapFromRefundPayment),
      "lastTransactionInfo": status.lastTransactionInfo.map(mapFromLastTransactionInfo),
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

  private func mapFromRevokedPayment(_ payment: RevokedPayment) -> [String: Any?] {
    [
      "paymentId": payment.paymentId,
      "paymentStatus": payment.paymentStatus,
    ]
  }

  private func mapFromRefundPayment(_ payment: RefundPayment) -> [String: Any?] {
    [
      "paymentId": payment.paymentId,
      "paymentStatus": payment.paymentStatus,
      "amount": payment.amount.map(decimalToDouble),
      "paymentDate": payment.paymentDate,
      "reference": payment.reference,
    ]
  }

  private func mapFromLastTransactionInfo(_ info: LastTransactionInfo) -> [String: Any?] {
    [
      "status": info.status,
      "failureCode": info.failureCode,
      "failureDescription": info.failureDescription,
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

  private func mapFromPaymentStatus(_ status: PaymentResponse.Status) -> String {
    switch status {
    case .new:
      return "New"
    case .waiting:
      return "Waiting"
    case .processing:
      return "Processing"
    case .incomplete:
      return "Incomplete"
    case .success:
      return "Success"
    case .error:
      return "Error"
    case let .unknown(value):
      return "Unknown(\(value))"
    }
  }

  private func decimalToDouble(_ decimal: Decimal) -> Double {
    NSDecimalNumber(decimal: decimal).doubleValue
  }

  private func mapExtraParams(_ rawValue: Any?) -> [String: String]? {
    guard let rawMap = rawValue as? [String: Any] else {
      return nil
    }
    var params: [String: String] = [:]
    for (key, value) in rawMap {
      params[key] = String(describing: value)
    }
    return params.isEmpty ? nil : params
  }
}

private extension String {
  var nonEmpty: String? {
    isEmpty ? nil : self
  }
}
