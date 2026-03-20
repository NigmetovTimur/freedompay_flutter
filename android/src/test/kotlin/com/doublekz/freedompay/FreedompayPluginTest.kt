package com.doublekz.freedompay

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

internal class FreedompayPluginTest {
    @Test
    fun createApplePayment_returnsUnsupportedPayloadOnAndroid() {
        val plugin = FreedompayPlugin()
        val result = CapturingResult()

        plugin.onMethodCall(MethodCall("createApplePayment", emptyMap<String, Any>()), result)

        val payload = result.successValue as? Map<*, *>
        assertNotNull(payload)
        assertNull(payload["paymentId"])
        val error = payload["error"] as? Map<*, *>
        assertNotNull(error)
        assertEquals("UNSUPPORTED", error["errorCode"])
    }

    @Test
    fun confirmApplePayment_returnsUnsupportedPayloadOnAndroid() {
        val plugin = FreedompayPlugin()
        val result = CapturingResult()

        plugin.onMethodCall(MethodCall("confirmApplePayment", emptyMap<String, Any>()), result)

        val payload = result.successValue as? Map<*, *>
        assertNotNull(payload)
        assertNull(payload["payment"])
        val error = payload["error"] as? Map<*, *>
        assertNotNull(error)
        assertEquals("UNSUPPORTED", error["errorCode"])
    }

    private class CapturingResult : MethodChannel.Result {
        var successValue: Any? = null
        var errorCode: String? = null
        var errorMessage: String? = null
        var errorDetails: Any? = null
        var notImplemented = false

        override fun success(result: Any?) {
            successValue = result
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            this.errorCode = errorCode
            this.errorMessage = errorMessage
            this.errorDetails = errorDetails
        }

        override fun notImplemented() {
            notImplemented = true
        }
    }
}
