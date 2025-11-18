package com.doublekz.freedompay

import android.app.Activity
import android.graphics.Color
import android.util.Log
import android.view.ViewGroup
import android.widget.FrameLayout
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
// MIGRATED: old PayBox SDK -> new FreedomPay Merchant SDK
import kz.freedompay.paymentsdk.api.FreedomAPI
import kz.freedompay.paymentsdk.api.model.ClearingStatus
import kz.freedompay.paymentsdk.api.model.FreedomResult
import kz.freedompay.paymentsdk.api.model.GooglePayment
import kz.freedompay.paymentsdk.api.model.PaymentResponse
import kz.freedompay.paymentsdk.api.model.StandardPaymentRequest
import kz.freedompay.paymentsdk.api.model.Status
import kz.freedompay.paymentsdk.api.model.TokenizedPaymentRequest
import kz.freedompay.paymentsdk.api.model.ValidationErrorType
import kz.freedompay.paymentsdk.api.model.config.Region
import kz.freedompay.paymentsdk.api.model.config.SdkConfiguration
import kz.freedompay.paymentsdk.api.model.config.OperationalConfiguration
import kz.freedompay.paymentsdk.api.model.config.UserConfiguration
import kz.freedompay.paymentsdk.api.view.PaymentView
import java.util.HashMap
import java.util.Locale

/** FreedompayPlugin */
class FreedompayPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var freedomApi: FreedomAPI? = null
    private var overlayContainer: FrameLayout? = null
    private var operationalConfiguration = OperationalConfiguration(testingMode = null)
    private var userConfiguration = UserConfiguration()
    private var sdkConfiguration = SdkConfiguration(
        userConfiguration = userConfiguration,
        operationalConfiguration = operationalConfiguration
    )

    companion object {
        private const val TAG = "FreedompayPlugin"
    }

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
            "setResultUrl" -> handleSetResultUrl(call, result)
            "setCheckUrl" -> handleSetCheckUrl(call, result)
            "setUserPhone" -> handleSetUserPhone(call, result)
            "setUserContactEmail" -> handleSetUserContactEmail(call, result)
            "setUserEmail" -> handleSetUserEmail(call, result)
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
        // Region is not part of the public Dart API; defaulting to KZ for backward compatibility.
        freedomApi = FreedomAPI.create(merchantId.toString(), secretKey, Region.KZ).apply {
            setConfiguration(sdkConfiguration)
        }
        result.success(null)
    }

    private fun handleSetResultUrl(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
        if (url.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "url is required", null)
            return
        }
        operationalConfiguration = operationalConfiguration.copy(resultUrl = url)
        applyConfiguration()
        result.success(null)
    }

    private fun handleSetUserPhone(call: MethodCall, result: Result) {
        val phone = call.argument<String>("phone")
        userConfiguration = userConfiguration.copy(userPhone = phone)
        applyConfiguration()
        result.success(null)
    }

    private fun handleSetUserContactEmail(call: MethodCall, result: Result) {
        val email = call.argument<String>("email")
        userConfiguration = userConfiguration.copy(userContactEmail = email)
        applyConfiguration()
        result.success(null)
    }

    private fun handleSetUserEmail(call: MethodCall, result: Result) {
        val email = call.argument<String>("email")
        userConfiguration = userConfiguration.copy(userEmail = email)
        applyConfiguration()
        result.success(null)
    }

    private fun handleSetCheckUrl(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
        if (url.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "url is required", null)
            return
        }
        operationalConfiguration = operationalConfiguration.copy(checkUrl = url)
        applyConfiguration()
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
        Log.d(
            TAG,
            "createPayment request: amount=$amount, description=$description, orderId=$orderId, userId=$userId, extraParams=$extraParams, userConfiguration=$userConfiguration"
        )
        withPaymentView(result) { paymentView ->
            sdk.setPaymentView(paymentView)
            val request = StandardPaymentRequest(
                amount = amount,
                description = description,
                userId = userId,
                orderId = orderId,
                extraParams = extraParams
            )
            sdk.createPaymentPage(request) { paymentResult ->
                Log.d(TAG, "createPayment result: $paymentResult")
                val (paymentMap, errorMap) = paymentResult.asPaymentResponse()
                deliverResult(result, mapOf("payment" to paymentMap, "error" to errorMap))
            }
        }
    }

    private fun handleCreateRecurringPayment(call: MethodCall, result: Result) {
        // Not available in the new SDK; preserve API shape with an explicit error payload.
        deliverResult(
            result,
            mapOf("recurringPayment" to null, "error" to mapOf("errorCode" to "UNSUPPORTED", "description" to "Recurring payments are not supported by the FreedomPay Android SDK"))
        )
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
        val cardToken = call.argument<String>("cardToken")
        val extraParams = call.argument<Map<String, Any?>>("extraParams").toHashMap()
        if (cardToken.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "cardToken is required for the new SDK", null)
            return
        }
        val request = TokenizedPaymentRequest(
            amount = amount,
            description = description,
            cardToken = cardToken,
            userId = userId,
            orderId = orderId,
            extraParams = extraParams
        )
        sdk.createCardPayment(request) { paymentResult ->
            val (paymentMap, errorMap) = paymentResult.asPaymentResponse()
            deliverResult(result, mapOf("payment" to paymentMap, "error" to errorMap))
        }
    }

    private fun handlePayByCard(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<Int>("paymentId")
        if (paymentId == null) {
            result.error("INVALID_ARGUMENTS", "paymentId is required", null)
            return
        }
        sdk.confirmCardPayment(paymentId.toLong()) { paymentResult ->
            val (paymentMap, errorMap) = paymentResult.asPaymentResponse()
            deliverResult(result, mapOf("payment" to paymentMap, "error" to errorMap))
        }
    }

    private fun handleGetPaymentStatus(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<Int>("paymentId")
        if (paymentId == null) {
            result.error("INVALID_ARGUMENTS", "paymentId is required", null)
            return
        }
        sdk.getPaymentStatus(paymentId.toLong(), null) { statusResult ->
            when (statusResult) {
                is FreedomResult.Success -> deliverResult(result, mapOf("status" to statusResult.value.toMap(), "error" to null))
                is FreedomResult.Error -> deliverResult(result, mapOf("status" to null, "error" to statusResult.toErrorMap()))
            }
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
        sdk.makeRevokePayment(paymentId.toLong(), amount) { paymentResult ->
            val (paymentMap, errorMap) = paymentResult.asPaymentResponse()
            deliverResult(result, mapOf("payment" to paymentMap, "error" to errorMap))
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
        sdk.makeClearingPayment(paymentId.toLong(), amount) { clearingResult ->
            when (clearingResult) {
                is FreedomResult.Success -> deliverResult(
                    result,
                    mapOf("capture" to clearingResult.value.toMap(), "error" to null)
                )
                is FreedomResult.Error -> deliverResult(result, mapOf("capture" to null, "error" to clearingResult.toErrorMap()))
            }
        }
    }

    private fun handleMakeCancelPayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<Int>("paymentId")
        if (paymentId == null) {
            result.error("INVALID_ARGUMENTS", "paymentId is required", null)
            return
        }
        sdk.makeCancelPayment(paymentId.toLong()) { paymentResult ->
            val (paymentMap, errorMap) = paymentResult.asPaymentResponse()
            deliverResult(result, mapOf("payment" to paymentMap, "error" to errorMap))
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
            sdk.addNewCard(userId, postLink) { paymentResult ->
                val (paymentMap, errorMap) = paymentResult.asPaymentResponse()
                deliverResult(result, mapOf("payment" to paymentMap, "error" to errorMap))
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
        // New SDK requires card token; fall back to stringified cardId to preserve compatibility.
        sdk.removeAddedCard(cardId.toString(), userId) { cardResult ->
            when (cardResult) {
                is FreedomResult.Success -> deliverResult(result, mapOf("card" to cardResult.value.toMap(), "error" to null))
                is FreedomResult.Error -> deliverResult(result, mapOf("card" to null, "error" to cardResult.toErrorMap()))
            }
        }
    }

    private fun handleGetAddedCards(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val userId = call.argument<String>("userId")
        if (userId.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "userId is required", null)
            return
        }
        sdk.getAddedCards(userId) { cardsResult ->
            when (cardsResult) {
                is FreedomResult.Success -> deliverResult(result, mapOf("cards" to cardsResult.value.map { it.toMap() }, "error" to null))
                is FreedomResult.Error -> deliverResult(result, mapOf("cards" to null, "error" to cardsResult.toErrorMap()))
            }
        }
    }

    private fun handleCreateNonAcceptancePayment(call: MethodCall, result: Result) {
        val sdk = ensureSdk(result) ?: return
        val paymentId = call.argument<Int>("paymentId")
        if (paymentId == null) {
            result.error("INVALID_ARGUMENTS", "paymentId is required", null)
            return
        }
        sdk.confirmDirectPayment(paymentId.toLong()) { paymentResult ->
            val (paymentMap, errorMap) = paymentResult.asPaymentResponse()
            deliverResult(result, mapOf("payment" to paymentMap, "error" to errorMap))
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
        val request = StandardPaymentRequest(
            amount = amount,
            description = description,
            userId = userId,
            orderId = orderId,
            extraParams = extraParams
        )
        sdk.createGooglePayment(request) { googleResult ->
            when (googleResult) {
                is FreedomResult.Success -> deliverResult(result, mapOf("paymentId" to googleResult.value.paymentId, "error" to null))
                is FreedomResult.Error -> deliverResult(result, mapOf("paymentId" to null, "error" to googleResult.toErrorMap()))
            }
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
        sdk.confirmGooglePayment(GooglePayment(paymentId), token) { paymentResult ->
            val (paymentMap, errorMap) = paymentResult.asPaymentResponse()
            deliverResult(result, mapOf("payment" to paymentMap, "error" to errorMap))
        }
    }

    private fun ensureSdk(result: Result): FreedomAPI? {
        val sdk = freedomApi
        if (sdk == null) {
            result.error("NOT_INITIALIZED", "FreedomPay SDK is not initialized", null)
        }
        return sdk
    }

    private fun applyConfiguration() {
        sdkConfiguration = sdkConfiguration.copy(
            userConfiguration = userConfiguration,
            operationalConfiguration = operationalConfiguration
        )
        freedomApi?.setConfiguration(sdkConfiguration)
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

private fun PaymentResponse.toMap(): Map<String, Any?> = mapOf(
    "status" to status.toReadable(),
    "paymentId" to paymentId,
    "redirectUrl" to null, // Not provided by the new SDK
    "merchantId" to merchantId,
    "orderId" to orderId
)

private fun PaymentResponse.Status.toReadable(): String = when (this) {
    is PaymentResponse.Status.Error -> "Error"
    PaymentResponse.Status.Incomplete -> "Incomplete"
    PaymentResponse.Status.New -> "New"
    PaymentResponse.Status.Processing -> "Processing"
    PaymentResponse.Status.Success -> "Success"
    PaymentResponse.Status.Waiting -> "Waiting"
    is PaymentResponse.Status.Unknown -> "Unknown(${this.value})"
}

private fun Status.toMap(): Map<String, Any?> = mapOf(
    "status" to status,
    "paymentId" to paymentId,
    "transactionStatus" to paymentStatus,
    "canReject" to canReject,
    "paymentMethod" to paymentMethod,
    "clearingAmount" to clearingAmount,
    "revokedAmount" to revokedAmount,
    "refundAmount" to refundAmount,
    "currency" to currency,
    "amount" to amount,
    "orderId" to orderId
)

private fun ClearingStatus.toMap(): Map<String, Any?> = when (this) {
    is ClearingStatus.Success -> mapOf("status" to "Success", "amount" to amount)
    ClearingStatus.Failed -> mapOf("status" to "Failed")
    ClearingStatus.ExceedsPaymentAmount -> mapOf("status" to "ExceedsPaymentAmount")
    else -> mapOf("status" to this.toString())
}

private fun kz.freedompay.paymentsdk.api.model.Card.toMap(): Map<String, Any?> = mapOf(
    "status" to status,
    "merchantId" to merchantId,
    "cardId" to null, // Card ID is not exposed; placeholder to keep API shape
    "recurringProfile" to recurringProfileId,
    "cardhash" to cardHash,
    "date" to createdAt,
    "cardToken" to cardToken
)

private fun kz.freedompay.paymentsdk.api.model.RemovedCard.toMap(): Map<String, Any?> = mapOf(
    "status" to status,
    "merchantId" to merchantId,
    "cardId" to null,
    "recurringProfile" to null,
    "cardhash" to cardHash,
    "date" to deletedAt,
    "cardToken" to null
)

private fun FreedomResult<PaymentResponse>.asPaymentResponse(): Pair<Map<String, Any?>?, Map<String, Any?>?> = when (this) {
    is FreedomResult.Success -> Pair(value.toMap(), null)
    is FreedomResult.Error -> Pair(null, this.toErrorMap())
}

private fun FreedomResult.Error.toErrorMap(): Map<String, Any?> = when (this) {
    is FreedomResult.Error.ValidationError -> mapOf(
        "errorCode" to "ValidationError",
        "description" to errors.joinToString(",") { it.readable() }
    )

    is FreedomResult.Error.InfrastructureError.ParsingError -> mapOf(
        "errorCode" to "ParsingError",
        "description" to "Failed to parse response"
    )

    is FreedomResult.Error.InfrastructureError.SdkNotConfigured -> mapOf(
        "errorCode" to "SdkNotConfigured",
        "description" to "SDK not configured"
    )

    is FreedomResult.Error.InfrastructureError.SdkCleared -> mapOf(
        "errorCode" to "SdkCleared",
        "description" to "SDK cleared before completion"
    )

    is FreedomResult.Error.InfrastructureError.WebView.PaymentViewIsNotInitialized -> mapOf(
        "errorCode" to "PaymentViewIsNotInitialized",
        "description" to "PaymentView is not attached"
    )

    is FreedomResult.Error.InfrastructureError.WebView.Failed -> mapOf(
        "errorCode" to "WebViewFailed",
        "description" to "Payment page failed"
    )

    is FreedomResult.Error.NetworkError.Connectivity.ConnectionFailed -> mapOf(
        "errorCode" to "ConnectionFailed",
        "description" to "Connection failed"
    )

    is FreedomResult.Error.NetworkError.Connectivity.ConnectionTimeout -> mapOf(
        "errorCode" to "ConnectionTimeout",
        "description" to "Connection timeout"
    )

    is FreedomResult.Error.NetworkError.Connectivity.Integrity -> mapOf(
        "errorCode" to "NetworkIntegrity",
        "description" to "Network integrity issue"
    )

    is FreedomResult.Error.NetworkError.Protocol -> mapOf(
        "errorCode" to "Protocol",
        "description" to "Protocol error"
    )

    is FreedomResult.Error.NetworkError.Unknown -> mapOf(
        "errorCode" to "NetworkUnknown",
        "description" to "Unknown network error"
    )

    is FreedomResult.Error.PaymentInitializationFailed -> mapOf(
        "errorCode" to "PaymentInitializationFailed",
        "description" to "Failed to initialize payment"
    )

    is FreedomResult.Error.Transaction -> mapOf(
        "errorCode" to "TransactionError",
        "description" to "Transaction failed",
        "details" to this.toString()
    )

    else -> mapOf(
        "errorCode" to this.javaClass.simpleName,
        "description" to this.toString(),
        "details" to this.toString()
    )
}

private fun ValidationErrorType.readable(): String {
    val rawName = this.name
    return if (rawName.contains("_")) {
        rawName.split("_")
            .joinToString(separator = "") { part ->
                part.lowercase().replaceFirstChar { char ->
                    char.titlecase(Locale.getDefault())
                }
            }
    } else {
        rawName
    }
}
