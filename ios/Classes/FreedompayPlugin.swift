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
  private var activePaymentSession: PaymentViewSession?
  private let paymentPresentationTimeout: TimeInterval = 3
  private let paymentLoadStartTimeout: TimeInterval = 10

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

    executePaymentViewFlow(flowName: "createPayment", api: api, result: result) { completion in
      self.log(
        "Invoking FreedomPaymentSdk.createPaymentPage",
        details: [
          "flow": "createPayment",
          "orderId": arguments["orderId"] as? String,
          "userId": arguments["userId"] as? String,
        ]
      )
      api.createPaymentPage(paymentRequest: request, onResult: completion)
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

    executePaymentViewFlow(flowName: "createPaymentFrame", api: api, result: result) { completion in
      self.log(
        "Invoking FreedomPaymentSdk.createPaymentFrame",
        details: [
          "flow": "createPaymentFrame",
          "orderId": arguments["orderId"] as? String,
          "userId": arguments["userId"] as? String,
        ]
      )
      api.createPaymentFrame(paymentRequest: request, onResult: completion)
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

    executePaymentViewFlow(flowName: "payByCard", api: api, result: result) { completion in
      self.log(
        "Invoking FreedomPaymentSdk.confirmCardPayment",
        details: [
          "flow": "payByCard",
          "paymentId": paymentId.int64Value,
        ]
      )
      api.confirmCardPayment(paymentId.int64Value, onResult: completion)
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

    executePaymentViewFlow(flowName: "addNewCard", api: api, result: result) { completion in
      self.log(
        "Invoking FreedomPaymentSdk.addNewCard",
        details: [
          "flow": "addNewCard",
          "orderId": orderId,
          "userId": userId,
        ]
      )
      api.addNewCard(userId: userId, orderId: orderId, onResult: completion)
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

    executePaymentViewFlow(flowName: "createNonAcceptancePayment", api: api, result: result) { completion in
      self.log(
        "Invoking FreedomPaymentSdk.confirmDirectPayment",
        details: [
          "flow": "createNonAcceptancePayment",
          "paymentId": paymentId.int64Value,
        ]
      )
      api.confirmDirectPayment(paymentId.int64Value, onResult: completion)
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

  private func executePaymentViewFlow(
    flowName: String,
    api: FreedomAPI,
    result: @escaping FlutterResult,
    action: @escaping (@escaping (FreedomResult<PaymentResponse>) -> Void) -> Void
  ) {
    DispatchQueue.main.async {
      if let session = self.activePaymentSession, !session.isCompleted {
        self.log(
          "Rejecting payment flow because another flow is still active",
          details: [
            "flow": flowName,
            "activeFlow": session.flowName,
          ]
        )
        result(
          self.paymentViewFailurePayload(
            flowName: flowName,
            code: "PAYMENT_IN_PROGRESS",
            description: "Another FreedomPay UI flow is already in progress",
            details: ["activeFlow": session.flowName]
          )
        )
        return
      }

      guard let target = self.resolvePresentationTarget() else {
        let diagnostics = self.presentationDiagnostics()
        self.log(
          "Unable to resolve an iOS presenter for PaymentView",
          details: [
            "flow": flowName,
            "diagnostics": diagnostics,
          ]
        )
        result(
          self.paymentViewFailurePayload(
            flowName: flowName,
            code: "NO_PRESENTING_CONTROLLER",
            description: "Unable to resolve an active iOS view controller for FreedomPay presentation",
            details: diagnostics
          )
        )
        return
      }

      let controller = FreedompayPaymentViewController(flowName: flowName)
      let session = PaymentViewSession(
        flowName: flowName,
        controller: controller,
        result: result
      )
      self.activePaymentSession = session

      controller.onDidAppear = { [weak self, weak session, weak controller] in
        guard let self, let session, let controller else { return }
        self.handlePaymentControllerDidAppear(session: session) {
          let paymentView = controller.paymentView
          paymentView.onLoadingStateChanged { [weak self, weak session] isLoading in
            guard let self, let session else { return }
            self.handleLoadingStateChanged(isLoading, session: session)
          }
          self.log(
            "PaymentView attached to presentation controller",
            details: [
              "flow": flowName,
              "paymentViewFrame": encodeRect(paymentView.frame),
              "paymentViewWindowAttached": paymentView.window != nil,
            ]
          )
          api.setPaymentView(paymentView)
          self.log("FreedomAPI.setPaymentView finished", details: ["flow": flowName])
          self.startLoadingWatchdog(for: session)
          action { [weak self, weak session] sdkResult in
            guard let self, let session else { return }
            self.handlePaymentViewResult(sdkResult, session: session)
          }
        }
      }

      controller.onDismissed = { [weak self, weak session] in
        guard let self, let session else { return }
        self.handleUnexpectedPaymentControllerDismissal(session: session)
      }

      self.log(
        "Presenting full-screen FreedomPay controller",
        details: [
          "flow": flowName,
          "presenter": self.describe(controller: target.presenter),
          "window": self.describe(window: target.window),
        ]
      )
      self.startPresentationWatchdog(for: session)
      target.presenter.present(controller, animated: true) { [weak self, weak session] in
        guard let self, let session else { return }
        self.log(
          "FreedomPay presentation completion block fired",
          details: [
            "flow": flowName,
            "didAppear": session.didAppear,
            "controller": self.describe(controller: controller),
          ]
        )
      }
    }
  }

  private func resolvePresentationTarget() -> PaymentPresentationTarget? {
    let windowScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
    let windows = windowScenes
      .flatMap(\.windows)
      .filter {
        !$0.isHidden &&
        $0.alpha > 0 &&
        $0.windowLevel == .normal &&
        $0.rootViewController != nil
      }
    let window = windows.first(where: \.isKeyWindow) ?? windows.first
    guard let window, let rootController = window.rootViewController else {
      return nil
    }

    let resolvedPresenter = resolveTopViewController(from: rootController) ?? rootController
    if resolvedPresenter is UIAlertController, let presentingController = resolvedPresenter.presentingViewController {
      return PaymentPresentationTarget(window: window, presenter: presentingController)
    }
    return PaymentPresentationTarget(window: window, presenter: resolvedPresenter)
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

  private func handlePaymentControllerDidAppear(
    session: PaymentViewSession,
    onReady: @escaping () -> Void
  ) {
    DispatchQueue.main.async {
      guard self.activePaymentSession === session, !session.isCompleted, !session.didAppear else {
        return
      }

      session.didAppear = true
      session.presentationWatchdog?.cancel()
      session.controller.view.layoutIfNeeded()
      self.log(
        "FreedomPay controller did appear",
        details: [
          "flow": session.flowName,
          "controller": self.describe(controller: session.controller),
          "window": self.describe(window: session.controller.view.window),
        ]
      )
      onReady()
    }
  }

  private func startPresentationWatchdog(for session: PaymentViewSession) {
    let watchdog = DispatchWorkItem { [weak self, weak session] in
      guard let self, let session else { return }
      guard self.activePaymentSession === session, !session.isCompleted, !session.didAppear else {
        return
      }

      self.log(
        "FreedomPay presentation timed out before viewDidAppear",
        details: [
          "flow": session.flowName,
          "controller": self.describe(controller: session.controller),
        ]
      )
      self.completePaymentViewFlow(
        session: session,
        payload: self.paymentViewFailurePayload(
          flowName: session.flowName,
          code: "PAYMENT_VIEW_PRESENTATION_TIMEOUT",
          description: "FreedomPay payment screen was not presented on iOS",
          details: [
            "stage": "present",
            "controller": self.describe(controller: session.controller),
          ]
        )
      )
    }

    session.presentationWatchdog = watchdog
    DispatchQueue.main.asyncAfter(deadline: .now() + paymentPresentationTimeout, execute: watchdog)
  }

  private func startLoadingWatchdog(for session: PaymentViewSession) {
    let watchdog = DispatchWorkItem { [weak self, weak session] in
      guard let self, let session else { return }
      guard self.activePaymentSession === session, !session.isCompleted, !session.didStartLoading else {
        return
      }

      self.log(
        "FreedomPay payment page did not start loading in time",
        details: [
          "flow": session.flowName,
          "controller": self.describe(controller: session.controller),
          "window": self.describe(window: session.controller.view.window),
        ]
      )
      self.completePaymentViewFlow(
        session: session,
        payload: self.paymentViewFailurePayload(
          flowName: session.flowName,
          code: "PAYMENT_VIEW_NOT_LOADING",
          description: "FreedomPay payment page did not start loading after presentation",
          details: [
            "stage": "load",
            "paymentViewWindowAttached": session.controller.paymentView.window != nil,
            "paymentViewFrame": encodeRect(session.controller.paymentView.frame),
          ]
        )
      )
    }

    session.loadingWatchdog = watchdog
    DispatchQueue.main.asyncAfter(deadline: .now() + paymentLoadStartTimeout, execute: watchdog)
  }

  private func handleLoadingStateChanged(_ isLoading: Bool, session: PaymentViewSession) {
    DispatchQueue.main.async {
      guard self.activePaymentSession === session, !session.isCompleted else {
        return
      }

      session.controller.setLoading(isLoading)
      self.log(
        "PaymentView loading state changed",
        details: [
          "flow": session.flowName,
          "isLoading": isLoading,
          "didStartLoading": session.didStartLoading,
        ]
      )

      if isLoading {
        session.didStartLoading = true
        session.loadingWatchdog?.cancel()
      }
    }
  }

  private func handlePaymentViewResult(
    _ sdkResult: FreedomResult<PaymentResponse>,
    session: PaymentViewSession
  ) {
    DispatchQueue.main.async {
      guard self.activePaymentSession === session, !session.isCompleted else {
        return
      }

      let payload: [String: Any?]
      switch sdkResult {
      case let .success(payment):
        let mappedPayment = self.mapFromPaymentResponse(payment)
        self.log(
          "FreedomPay SDK returned success",
          details: [
            "flow": session.flowName,
            "paymentId": payment.paymentId,
            "status": self.mapFromPaymentStatus(payment.status),
          ]
        )
        payload = [
          "payment": mappedPayment,
          "error": NSNull(),
        ]
      case let .error(error):
        let mappedError = self.mapFromError(error)
        self.log(
          "FreedomPay SDK returned error",
          details: [
            "flow": session.flowName,
            "error": mappedError,
          ]
        )
        payload = [
          "payment": NSNull(),
          "error": mappedError,
        ]
      }

      self.completePaymentViewFlow(session: session, payload: self.cleanDictionary(payload))
    }
  }

  private func handleUnexpectedPaymentControllerDismissal(session: PaymentViewSession) {
    DispatchQueue.main.async {
      guard self.activePaymentSession === session, !session.isCompleted else {
        return
      }

      self.log(
        "FreedomPay controller was dismissed before SDK completion",
        details: ["flow": session.flowName]
      )
      self.completePaymentViewFlow(
        session: session,
        payload: self.paymentViewFailurePayload(
          flowName: session.flowName,
          code: "PAYMENT_VIEW_DISMISSED",
          description: "FreedomPay payment screen was dismissed before the SDK completed",
          details: ["stage": "dismiss"]
        )
      )
    }
  }

  private func completePaymentViewFlow(session: PaymentViewSession, payload: [String: Any]) {
    cancelWatchdogs(for: session)
    session.isCompleted = true
    activePaymentSession = nil

    let finishResult = {
      session.result(payload)
    }

    if session.controller.presentingViewController != nil {
      session.controller.dismiss(animated: true, completion: finishResult)
    } else {
      finishResult()
    }
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
    var mapped: [String: Any?] = [
      "status": mapFromPaymentStatus(payment.status),
      "paymentId": payment.paymentId,
      "merchantId": payment.merchantId,
      "orderId": payment.orderId,
      "redirectUrl": NSNull(),
    ]
    if case let .error(code, description) = payment.status {
      mapped["failureCode"] = code
      mapped["failureDescription"] = description
    }
    return mapped
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
        "description": errorDescription ?? "Transaction failed with code \(errorCode)",
      ]
    case let .validationError(errors):
      let message = errors.map { $0.rawValue }.joined(separator: ", ")
      return [
        "errorCode": "ValidationError",
        "description": message,
        "details": ["errors": errors.map { $0.rawValue }],
      ]
    case .paymentInitializationFailed:
      return [
        "errorCode": "PaymentInitializationFailed",
        "description": "Payment initialization failed",
      ]
    case let .networkError(networkError):
      return mapFromNetworkError(networkError)
    case let .infrastructureError(infraError):
      return mapFromInfrastructureError(infraError)
    }
  }

  private func mapFromNetworkError(_ error: NetworkError) -> [String: Any?] {
    switch error {
    case let .protocol(code, body):
      return [
        "errorCode": "Protocol",
        "description": "Protocol error (HTTP \(code))",
        "details": [
          "code": code,
          "body": body,
        ],
      ]
    case let .connectivity(connectivity):
      switch connectivity {
      case .connectionFailed:
        return [
          "errorCode": "ConnectionFailed",
          "description": "Network connection failed",
        ]
      case .connectionTimeout:
        return [
          "errorCode": "ConnectionTimeout",
          "description": "Network connection timed out",
        ]
      case .integrity:
        return [
          "errorCode": "NetworkIntegrity",
          "description": "Network integrity check failed",
        ]
      }
    case .unknown:
      return [
        "errorCode": "NetworkUnknown",
        "description": "Unknown network error",
      ]
    }
  }

  private func mapFromInfrastructureError(_ error: InfrastructureError) -> [String: Any?] {
    switch error {
    case .sdkNotConfigured:
      return [
        "errorCode": "SdkNotConfigured",
        "description": "SDK is not configured",
      ]
    case .sdkCleared:
      return [
        "errorCode": "SdkCleared",
        "description": "SDK was cleared before completion",
      ]
    case .parsingError:
      return [
        "errorCode": "ParsingError",
        "description": "Failed to parse FreedomPay response",
      ]
    case let .webView(webViewError):
      switch webViewError {
      case .paymentViewIsNotInitialized:
        return [
          "errorCode": "PaymentViewIsNotInitialized",
          "description": "PaymentView is not attached to the active window hierarchy",
        ]
      case .failed:
        return [
          "errorCode": "WebViewFailed",
          "description": "Payment page failed inside the embedded web view",
        ]
      }
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
    case .error(_, _):
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

  private func paymentViewFailurePayload(
    flowName: String,
    code: String,
    description: String,
    details: [String: Any?] = [:]
  ) -> [String: Any] {
    var payloadDetails = details
    payloadDetails["flow"] = flowName
    return cleanDictionary([
      "payment": NSNull(),
      "error": [
        "errorCode": code,
        "description": description,
        "details": payloadDetails,
      ],
    ])
  }

  private func presentationDiagnostics() -> [String: Any?] {
    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    let windows = scenes
      .flatMap(\.windows)
      .map { window in
        let rootName = window.rootViewController.map { String(describing: type(of: $0)) } ?? "nil"
        return "\(type(of: window))(hidden:\(window.isHidden),key:\(window.isKeyWindow),level:\(window.windowLevel.rawValue),root:\(rootName))"
      }

    return [
      "sceneCount": scenes.count,
      "sceneStates": scenes.map { String(describing: $0.activationState) },
      "windows": windows,
    ]
  }

  private func cancelWatchdogs(for session: PaymentViewSession) {
    session.presentationWatchdog?.cancel()
    session.presentationWatchdog = nil
    session.loadingWatchdog?.cancel()
    session.loadingWatchdog = nil
  }

  private func describe(window: UIWindow?) -> [String: Any?] {
    guard let window else {
      return ["exists": false]
    }
    return [
      "exists": true,
      "class": String(describing: type(of: window)),
      "isKeyWindow": window.isKeyWindow,
      "isHidden": window.isHidden,
      "windowLevel": window.windowLevel.rawValue,
      "frame": encodeRect(window.frame),
      "rootViewController": window.rootViewController.map { String(describing: type(of: $0)) } ?? "nil",
    ]
  }

  private func describe(controller: UIViewController?) -> [String: Any?] {
    guard let controller else {
      return ["exists": false]
    }
    return [
      "exists": true,
      "class": String(describing: type(of: controller)),
      "isBeingPresented": controller.isBeingPresented,
      "isBeingDismissed": controller.isBeingDismissed,
      "viewInWindow": controller.viewIfLoaded?.window != nil,
      "presentedViewController": controller.presentedViewController.map {
        String(describing: type(of: $0))
      } ?? "nil",
    ]
  }

  private func log(_ message: String, details: [String: Any?] = [:]) {
    let prefix = "[FreedompayPlugin][iOS]"
    guard !details.isEmpty else {
      NSLog("%@ %@", prefix, message)
      return
    }

    let payload = cleanDictionary(details)
    if JSONSerialization.isValidJSONObject(payload),
       let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
       let json = String(data: data, encoding: .utf8)
    {
      NSLog("%@ %@ %@", prefix, message, json)
      return
    }

    NSLog("%@ %@ %@", prefix, message, String(describing: payload))
  }

  private func encodeRect(_ rect: CGRect) -> String {
    NSCoder.string(for: rect)
  }
}

private extension String {
  var nonEmpty: String? {
    isEmpty ? nil : self
  }
}

private struct PaymentPresentationTarget {
  let window: UIWindow
  let presenter: UIViewController
}

private final class PaymentViewSession {
  let flowName: String
  let controller: FreedompayPaymentViewController
  let result: FlutterResult
  var didAppear = false
  var didStartLoading = false
  var isCompleted = false
  var presentationWatchdog: DispatchWorkItem?
  var loadingWatchdog: DispatchWorkItem?

  init(
    flowName: String,
    controller: FreedompayPaymentViewController,
    result: @escaping FlutterResult
  ) {
    self.flowName = flowName
    self.controller = controller
    self.result = result
  }
}

@MainActor
private final class FreedompayPaymentViewController: UIViewController {
  let flowName: String
  let paymentView = PaymentView()
  private let activityIndicator = UIActivityIndicatorView(style: .large)
  private var didNotifyAppear = false
  var onDidAppear: (() -> Void)?
  var onDismissed: (() -> Void)?

  init(flowName: String) {
    self.flowName = flowName
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
    isModalInPresentation = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    paymentView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(paymentView)

    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.hidesWhenStopped = true
    activityIndicator.startAnimating()
    view.addSubview(activityIndicator)

    NSLayoutConstraint.activate([
      paymentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      paymentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      paymentView.topAnchor.constraint(equalTo: view.topAnchor),
      paymentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !didNotifyAppear else { return }
    didNotifyAppear = true
    onDidAppear?()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    guard isBeingDismissed || navigationController?.isBeingDismissed == true else {
      return
    }
    onDismissed?()
  }

  func setLoading(_ isLoading: Bool) {
    if isLoading {
      activityIndicator.startAnimating()
    } else {
      activityIndicator.stopAnimating()
    }
  }
}
