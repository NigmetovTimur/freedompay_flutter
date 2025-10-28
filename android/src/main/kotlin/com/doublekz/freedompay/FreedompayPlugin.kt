package com.doublekz.freedompay

import android.app.Activity
import android.graphics.Color
import android.view.ViewGroup
import android.widget.FrameLayout
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import money.paybox.payboxsdk.PayboxSdk
import money.paybox.payboxsdk.interfaces.PayboxSdkInterface
import money.paybox.payboxsdk.models.Capture
import money.paybox.payboxsdk.models.Card
import money.paybox.payboxsdk.models.Error
import money.paybox.payboxsdk.models.Payment
import money.paybox.payboxsdk.models.RecurringPayment
import money.paybox.payboxsdk.models.Status
import money.paybox.payboxsdk.view.PaymentView
import java.util.HashMap

/** FreedompayPlugin */
class FreedompayPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var payboxSdk: PayboxSdkInterface? = null
    private var overlayContainer: FrameLayout? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "freedompay")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "createPayment" -> handleCreatePayment(call, result)
            "createRecurringPayment" -> handleCreateRecurringPayment(call, result)
            "createCardPayment" -> handleCreateCardPayment(call, result)
            "payByCard" -> handlePayByCard(call, result)
            "getPaymentStatus" -> handleGetPaymentStatus(call, result)
            "makeRevokePayment" -> handleMakeRevokePayment(call, result)
            "makeClearingPayment" -> handleMakeClearingPayment(call, result)
            "makeCancelPayment" -> handleMakeCancelPayment(call, result)
            "addNewCard" -> handleAddNewCard(call, result)
            "removeAddedCard" -> handleRemoveAddedCard(call, result)
            "getAddedCards" -> handleGetAddedCards(call, result)
            "createNonAcceptancePayment" -> handleCreateNonAcceptancePayment(call, result)
            "createGooglePayment" -> handleCreateGooglePayment(call, result)
            "confirmGooglePayment" -> handleConfirmGooglePayment(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val merchantId = call.argument<Int>("merchantId")
        val secretKey = call.argument<String>("secretKey")
        if (merchantId == null || secretKey.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "merchantId and secretKey are required", null)
            return
        }
        payboxSdk = PayboxSdk.initialize(merchantId, secretKey)
        result.success(null)
    }

    private fun handleCreatePayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val amount = call.argument<Number>("amount")?.toFloat()
        val description = call.argument<String>("description")
        if (amount == null || description.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "amount and description are required", null)
            return
        }
        val orderId = call.argument<String>("orderId")
        val userId = call.argument<String>("userId")
        val extraParams = call.argument<Map<String, Any?>>("extraParams").toHashMap()
        withPaymentView(result) { paymentView ->
            sdk.setPaymentView(paymentView)
            sdk.createPayment(amount, description, orderId, userId, extraParams) { payment, error ->
                deliverResult(result, mapOf("payment" to payment?.toMap(), "error" to error?.toMap()))
            }
        }
    }

    private fun handleCreateRecurringPayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val amount = call.argument<Number>("amount")?.toFloat()
        val description = call.argument<String>("description")
        val recurringProfile = call.argument<String>("recurringProfile")
        if (amount == null || description.isNullOrEmpty() || recurringProfile.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "amount, description and recurringProfile are required", null)
            return
        }
        val orderId = call.argument<String>("orderId")
        val extraParams = call.argument<Map<String, Any?>>("extraParams").toHashMap()
        sdk.createRecurringPayment(amount, description, recurringProfile, orderId, extraParams) { recurring, error ->
            deliverResult(result, mapOf("recurringPayment" to recurring?.toMap(), "error" to error?.toMap()))
        }
    }

    private fun handleCreateCardPayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val amount = call.argument<Number>("amount")?.toFloat()
        val description = call.argument<String>("description")
        val orderId = call.argument<String>("orderId")
        val userId = call.argument<String>("userId")
        if (amount == null || description.isNullOrEmpty() || orderId.isNullOrEmpty() || userId.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "amount, description, orderId and userId are required", null)
            return
        }
        val cardId = call.argument<Int>("cardId")
        val cardToken = call.argument<String>("cardToken")
        val extraParams = call.argument<Map<String, Any?>>("extraParams").toHashMap()
        if (cardToken.isNullOrEmpty() && cardId == null) {
            result.error("INVALID_ARGUMENTS", "Either cardToken or cardId must be provided", null)
            return
        }
        val callback: (Payment?, Error?) -> Unit = { payment, error ->
            deliverResult(result, mapOf("payment" to payment?.toMap(), "error" to error?.toMap()))
        }
        if (!cardToken.isNullOrEmpty()) {
            sdk.createCardPayment(amount, userId, cardToken, description, orderId, extraParams, callback)
        } else {
            sdk.createCardPayment(amount, userId, cardId!!, description, orderId, extraParams, callback)
        }
    }

    private fun handlePayByCard(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<Int>("paymentId")
        if (paymentId == null) {
            result.error("INVALID_ARGUMENTS", "paymentId is required", null)
            return
        }
        withPaymentView(result) { paymentView ->
            sdk.setPaymentView(paymentView)
            sdk.payByCard(paymentId) { payment, error ->
                deliverResult(result, mapOf("payment" to payment?.toMap(), "error" to error?.toMap()))
            }
        }
    }

    private fun handleGetPaymentStatus(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<Int>("paymentId")
        if (paymentId == null) {
            result.error("INVALID_ARGUMENTS", "paymentId is required", null)
            return
        }
        sdk.getPaymentStatus(paymentId) { status, error ->
            deliverResult(result, mapOf("status" to status?.toMap(), "error" to error?.toMap()))
        }
    }

    private fun handleMakeRevokePayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<Int>("paymentId")
        val amount = call.argument<Number>("amount")?.toFloat()
        if (paymentId == null || amount == null) {
            result.error("INVALID_ARGUMENTS", "paymentId and amount are required", null)
            return
        }
        sdk.makeRevokePayment(paymentId, amount) { payment, error ->
            deliverResult(result, mapOf("payment" to payment?.toMap(), "error" to error?.toMap()))
        }
    }

    private fun handleMakeClearingPayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<Int>("paymentId")
        val amount = call.argument<Number>("amount")?.toFloat()
        if (paymentId == null) {
            result.error("INVALID_ARGUMENTS", "paymentId is required", null)
            return
        }
        sdk.makeClearingPayment(paymentId, amount) { capture, error ->
            deliverResult(result, mapOf("capture" to capture?.toMap(), "error" to error?.toMap()))
        }
    }

    private fun handleMakeCancelPayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<Int>("paymentId")
        if (paymentId == null) {
            result.error("INVALID_ARGUMENTS", "paymentId is required", null)
            return
        }
        sdk.makeCancelPayment(paymentId) { payment, error ->
            deliverResult(result, mapOf("payment" to payment?.toMap(), "error" to error?.toMap()))
        }
    }

    private fun handleAddNewCard(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val userId = call.argument<String>("userId")
        if (userId.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "userId is required", null)
            return
        }
        val postLink = call.argument<String>("postLink")
        withPaymentView(result) { paymentView ->
            sdk.setPaymentView(paymentView)
            sdk.addNewCard(userId, postLink) { payment, error ->
                deliverResult(result, mapOf("payment" to payment?.toMap(), "error" to error?.toMap()))
            }
        }
    }

    private fun handleRemoveAddedCard(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val cardId = call.argument<Int>("cardId")
        val userId = call.argument<String>("userId")
        if (cardId == null || userId.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "cardId and userId are required", null)
            return
        }
        sdk.removeAddedCard(cardId, userId) { card, error ->
            deliverResult(result, mapOf("card" to card?.toMap(), "error" to error?.toMap()))
        }
    }

    private fun handleGetAddedCards(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val userId = call.argument<String>("userId")
        if (userId.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "userId is required", null)
            return
        }
        sdk.getAddedCards(userId) { cards, error ->
            deliverResult(
                result,
                mapOf(
                    "cards" to cards?.map { it.toMap() },
                    "error" to error?.toMap()
                )
            )
        }
    }

    private fun handleCreateNonAcceptancePayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<Int>("paymentId")
        if (paymentId == null) {
            result.error("INVALID_ARGUMENTS", "paymentId is required", null)
            return
        }
        sdk.createNonAcceptancePayment(paymentId) { payment, error ->
            deliverResult(result, mapOf("payment" to payment?.toMap(), "error" to error?.toMap()))
        }
    }

    private fun handleCreateGooglePayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val amount = call.argument<Number>("amount")?.toFloat()
        val description = call.argument<String>("description")
        if (amount == null || description.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "amount and description are required", null)
            return
        }
        val orderId = call.argument<String>("orderId")
        val userId = call.argument<String>("userId")
        val extraParams = call.argument<Map<String, Any?>>("extraParams").toHashMap()
        sdk.createGooglePayment(amount, description, orderId, userId, extraParams) { paymentId, error ->
            deliverResult(result, mapOf("paymentId" to paymentId, "error" to error?.toMap()))
        }
    }

    private fun handleConfirmGooglePayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<String>("paymentId")
        val token = call.argument<String>("token")
        if (paymentId.isNullOrEmpty() || token.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "paymentId and token are required", null)
            return
        }
        sdk.confirmGooglePayment(paymentId, token) { payment, error ->
            deliverResult(result, mapOf("payment" to payment?.toMap(), "error" to error?.toMap()))
        }
    }

    private fun ensureSdk(result: Result): PayboxSdkInterface? {
        val sdk = payboxSdk
        if (sdk == null) {
            result.error("NOT_INITIALIZED", "Paybox SDK is not initialized", null)
        }
        return sdk
    }

    private fun deliverResult(result: Result, payload: Map<String, Any?>) {
        val activity = activity
        if (activity == null) {
            result.success(payload)
            return
        }
        activity.runOnUiThread {
            dismissOverlay()
            result.success(payload)
        }
    }

    private fun withPaymentView(result: Result, action: (PaymentView) -> Unit) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Plugin is not attached to an activity", null)
            return
        }
        currentActivity.runOnUiThread {
            dismissOverlay()
            val root = currentActivity.findViewById<ViewGroup>(android.R.id.content)
            val container = FrameLayout(currentActivity)
            container.setBackgroundColor(Color.WHITE)
            val paymentView = PaymentView(currentActivity)
            container.addView(
                paymentView,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            )
            root.addView(
                container,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            )
            overlayContainer = container
            try {
                action(paymentView)
            } catch (exception: Exception) {
                dismissOverlay()
                result.error("NATIVE_ERROR", exception.localizedMessage, null)
            }
        }
    }

    private fun dismissOverlay() {
        val currentActivity = activity ?: return
        val container = overlayContainer ?: return
        currentActivity.runOnUiThread {
            val parent = container.parent
            if (parent is ViewGroup) {
                parent.removeView(container)
            }
            overlayContainer = null
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}

private fun Map<String, Any?>?.toHashMap(): HashMap<String, String>? {
    if (this == null) return null
    val hashMap = HashMap<String, String>()
    for ((key, value) in this) {
        if (key != null && value != null) {
            hashMap[key] = value.toString()
        }
    }
    return hashMap
}

private fun Payment.toMap(): Map<String, Any?> = mapOf(
    "status" to status,
    "paymentId" to paymentId,
    "redirectUrl" to redirectUrl,
    "merchantId" to merchantId,
    "orderId" to orderId
)

private fun RecurringPayment.toMap(): Map<String, Any?> = mapOf(
    "status" to status,
    "paymentId" to paymentId,
    "currency" to currency,
    "amount" to amount,
    "recurringProfile" to recurringProfile,
    "recurringExpireDate" to recurringExpireDate
)

private fun Status.toMap(): Map<String, Any?> = mapOf(
    "status" to status,
    "paymentId" to paymentId,
    "transactionStatus" to transactionStatus,
    "canReject" to canReject,
    "isCaptured" to isCaptured,
    "cardPan" to cardPan,
    "createDate" to createDate
)

private fun Capture.toMap(): Map<String, Any?> = mapOf(
    "status" to status,
    "amount" to amount,
    "clearingAmount" to clearingAmount
)

private fun Card.toMap(): Map<String, Any?> = mapOf(
    "status" to status,
    "merchantId" to merchantId,
    "cardId" to cardId,
    "recurringProfile" to recurringProfile,
    "cardhash" to cardhash,
    "date" to date,
    "cardToken" to cardToken
)

private fun Error.toMap(): Map<String, Any?> = mapOf(
    "errorCode" to errorCode,
    "description" to description
)
