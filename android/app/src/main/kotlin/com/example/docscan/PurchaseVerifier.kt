package com.example.docscan

import android.util.Base64
import org.json.JSONObject
import java.security.KeyFactory
import java.security.Signature
import java.security.spec.X509EncodedKeySpec

/** Client-only signed proof. Current ownership/refunds are reconciled with Play
 * on launch/resume; offline proof cannot replace server-side revocation checks. */
object PurchaseVerifier {
    fun verify(payload: String, signature: String, publicKey: String,
               expectedPackage: String, expectedProduct: String,
               decode: (String) -> ByteArray = { Base64.decode(it, Base64.DEFAULT) }): Boolean {
        if (payload.isBlank() || payload.length > 262144 || signature.isBlank() ||
            signature.length > 8192 || publicKey.isBlank() || publicKey.length > 8192 ||
            expectedProduct.isBlank()) return false
        return try {
            val key = KeyFactory.getInstance("RSA").generatePublic(
                X509EncodedKeySpec(decode(publicKey)))
            val verifier = Signature.getInstance("SHA1withRSA")
            verifier.initVerify(key)
            verifier.update(payload.toByteArray(Charsets.UTF_8))
            if (!verifier.verify(decode(signature))) return false
            val json = JSONObject(payload)
            val product = json.optString("productId")
            val products = json.optJSONArray("productIds")
            val productMatches = product == expectedProduct || (products != null &&
                (0 until products.length()).any { products.optString(it) == expectedProduct })
            val token = json.optString("purchaseToken").ifBlank { json.optString("token") }
            json.optString("packageName") == expectedPackage && productMatches &&
                json.has("purchaseState") && json.getInt("purchaseState") == 0 && token.isNotBlank()
        } catch (_: Exception) { false }
    }
}
