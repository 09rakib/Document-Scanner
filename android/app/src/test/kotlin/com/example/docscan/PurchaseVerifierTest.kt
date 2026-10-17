package com.example.docscan

import org.junit.Assert.*
import org.junit.Test
import org.json.JSONObject
import java.security.KeyPairGenerator
import java.security.Signature
import java.util.Base64

class PurchaseVerifierTest {
    private val keys = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
    private val publicKey = Base64.getEncoder().encodeToString(keys.public.encoded)
    private fun payload(product: String = "docscan_remove_ads", pkg: String = "com.example.docscan",
                        state: Int = 0, token: String = "test-token"): String = JSONObject()
        .put("packageName", pkg).put("productId", product).put("purchaseState", state)
        .put("purchaseToken", token).toString()
    private fun sign(data: String): String = Base64.getEncoder().encodeToString(
        Signature.getInstance("SHA1withRSA").apply {
            initSign(keys.private); update(data.toByteArray(Charsets.UTF_8))
        }.sign())
    private fun verify(data: String, signature: String = sign(data), key: String = publicKey) =
        PurchaseVerifier.verify(data, signature, key, "com.example.docscan", "docscan_remove_ads") {
            Base64.getDecoder().decode(it)
        }
    @Test fun acceptsSignedCompletedPurchase() { assertTrue(verify(payload())) }
    @Test fun rejectsTamperedPayload() { val data = payload(); assertFalse(verify(data + " ", sign(data))) }
    @Test fun rejectsWrongKeyAndMalformedInput() {
        assertFalse(verify(payload(), key = "invalid")); assertFalse(verify("not JSON"))
        assertFalse(verify(payload(), signature = "invalid")); assertFalse(verify(payload(), key = ""))
    }
    @Test fun rejectsOtherPackageProductAndPendingState() {
        assertFalse(verify(payload(pkg = "other.app"))); assertFalse(verify(payload(product = "other")))
        assertFalse(verify(payload(state = 2))); assertFalse(verify(payload(token = "")))
    }
    @Test fun rejectsMissingPurchaseState() {
        val data = JSONObject(payload()).apply { remove("purchaseState") }.toString()
        assertFalse(verify(data))
    }
    @Test fun supportsSignedProductIdsArray() {
        val data = JSONObject(payload()).apply {
            remove("productId"); put("productIds", org.json.JSONArray().put("docscan_remove_ads"))
        }.toString()
        assertTrue(verify(data))
    }
}
