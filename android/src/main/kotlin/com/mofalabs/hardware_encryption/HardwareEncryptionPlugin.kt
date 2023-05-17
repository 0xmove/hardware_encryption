package com.mofalabs.hardware_encryption

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.math.BigInteger
import java.security.*
import java.security.spec.AlgorithmParameterSpec
import javax.crypto.Cipher
import javax.security.auth.x500.X500Principal

class HardwareEncryptionPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private val keyStore = KeyStore.getInstance("AndroidKeyStore").apply {
        load(null)
    }
    private val ALGORITHM = KeyProperties.KEY_ALGORITHM_RSA
    private val BLOCK_MODE = KeyProperties.BLOCK_MODE_ECB
    private val PADDING = KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1
    private val TRANSFORMATION = "$ALGORITHM/$BLOCK_MODE/$PADDING"

    private fun getRSACipher(): Cipher {
        return Cipher.getInstance(TRANSFORMATION)
    }

    private fun createRSAKeysIfNeeded(keyAlias: String, password: String?) {
        var privateKey = keyStore.getKey(keyAlias, password?.toCharArray()) as PrivateKey
        var publicKey = keyStore.getCertificate(keyAlias).publicKey

        if (privateKey == null || publicKey == null) {
            createKey(keyAlias)
            try {
                privateKey = keyStore.getKey(keyAlias, password?.toCharArray()) as PrivateKey
                publicKey = keyStore.getCertificate(keyAlias).publicKey
            } catch (ignored: Exception) {
                keyStore.deleteEntry(keyAlias)
            }
            if (privateKey == null || publicKey == null) {
                createKey(keyAlias)
            }
        }
    }

    private fun createKeyPairWithStrongBox(keyAlias: String): KeyPair {
        val spec = KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
        .setBlockModes(BLOCK_MODE)
        .setEncryptionPaddings(PADDING)
        .setRandomizedEncryptionRequired(false)
        .setUserAuthenticationRequired(true)
        .setUserAuthenticationValidityDurationSeconds(10)
        .setCertificateSubject(X500Principal("CN=$keyAlias"))
        .setDigests(KeyProperties.DIGEST_SHA256)
        .setCertificateSerialNumber(BigInteger.valueOf(1))
        .setIsStrongBoxBacked(true)
        .setInvalidatedByBiometricEnrollment(false)

        val kpGenerator = KeyPairGenerator.getInstance(ALGORITHM)
        kpGenerator.initialize(spec.build())
        return kpGenerator.genKeyPair()
    }

    private fun createKeyPair(keyAlias: String): KeyPair {
        val spec = KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
        .setBlockModes(BLOCK_MODE)
        .setEncryptionPaddings(PADDING)
        .setRandomizedEncryptionRequired(false)
        .setUserAuthenticationRequired(true)
        .setUserAuthenticationValidityDurationSeconds(10)
        .setCertificateSubject(X500Principal("CN=$keyAlias"))
        .setDigests(KeyProperties.DIGEST_SHA256)
        .setCertificateSerialNumber(BigInteger.valueOf(1))

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            spec.setInvalidatedByBiometricEnrollment(false)
        }

        val kpGenerator = KeyPairGenerator.getInstance(ALGORITHM)
        kpGenerator.initialize(spec.build())
        return kpGenerator.genKeyPair()
    }

    private fun createKey(keyAlias: String): KeyPair {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                return createKeyPairWithStrongBox(keyAlias)
            }
        } catch (e: StrongBoxUnavailableException) {
            println("\n==> create key strongbox exception:")
            println(e)
        } catch (e: Exception) {
            println("\n==> create key exception:")
            println(e)
        }

        return createKeyPair(keyAlias)
    }

    private fun encrypt(keyAlias: String, input: ByteArray, password: String?): ByteArray {
        if (keyStore.getCertificate(keyAlias) == null) {
            createRSAKeysIfNeeded(keyAlias, password)
        }
        val publicKey = keyStore.getCertificate(keyAlias).publicKey
        val cipher = getRSACipher()
        cipher.init(Cipher.ENCRYPT_MODE, publicKey)
        return cipher.doFinal(input)
    }

    private fun decrypt(keyAlias: String, input: ByteArray, password: String?): ByteArray {
        val privateKey = keyStore.getKey(keyAlias, password?.toCharArray())
        if (privateKey == null) {
            createRSAKeysIfNeeded(keyAlias, password)
        }
        val cipher = getRSACipher()
        cipher.init(Cipher.DECRYPT_MODE, privateKey)
        return cipher.doFinal(input)
    }

    private fun removeKey(keyAlias: String): Boolean {
        if (keyStore.containsAlias(keyAlias)) {
            keyStore.deleteEntry(keyAlias)
            return true
        }
        return false
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.mofalabs.hardware_encryption/hardware_encryption"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "encrypt" -> {
                val arguments = call.arguments as Map<*, *>
                val data = encrypt(
                    arguments["tag"] as String,
                    arguments["message"] as ByteArray,
                    arguments["password"] as String?,
                )
                result.success(data)
            }
            "decrypt" -> {
                val arguments = call.arguments as Map<*, *>
                val data = decrypt(
                    arguments["tag"] as String,
                    arguments["message"] as ByteArray,
                    arguments["password"] as String?,
                )
                result.success(data)
            }
            "removeKey" -> {
                val arguments = call.arguments as Map<*, *>
                val data = removeKey(
                    arguments["tag"] as String,
                )
                result.success(data)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

