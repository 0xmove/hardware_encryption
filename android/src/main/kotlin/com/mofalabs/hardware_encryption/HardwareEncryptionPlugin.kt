package com.mofalabs.hardware_encryption

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.SensorManager.DynamicSensorCallback
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.math.BigInteger
import java.security.*
import java.security.spec.AlgorithmParameterSpec
import java.util.*
import javax.crypto.Cipher
import javax.security.auth.x500.X500Principal

@Suppress("DEPRECATION")
class RsaKeyStoreKey(context: Context) {

    private val context: Context
    private val KEYSTORE_PROVIDER_ANDROID = "AndroidKeyStore"

    init {
        this.context = context
    }

    @Throws(Exception::class)
    fun encrypt(keyAlias: String, input: ByteArray, password: String?): ByteArray {
        createRSAKeysIfNeeded(keyAlias, password)
        val publicKey = getKeyStore().getCertificate(keyAlias).publicKey
        val cipher = getRSACipher()
        cipher.init(Cipher.ENCRYPT_MODE, publicKey)
        return cipher.doFinal(input)
    }

    @Throws(Exception::class)
    fun decrypt(keyAlias: String, input: ByteArray, password: String?): ByteArray {
        createRSAKeysIfNeeded(keyAlias, password)
        val privateKey = getKeyStore().getKey(keyAlias, password?.toCharArray())
        val cipher = getRSACipher()
        cipher.init(Cipher.DECRYPT_MODE, privateKey)
        return cipher.doFinal(input)
    }

    @Throws(Exception::class)
    private fun getKeyStore(): KeyStore {
        val ks = KeyStore.getInstance(KEYSTORE_PROVIDER_ANDROID)
        ks.load(null)
        return ks
    }

    @Throws(Exception::class)
    private fun getRSACipher(): Cipher {
        return if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            Cipher.getInstance(
                "RSA/ECB/PKCS1Padding",
                "AndroidOpenSSL"
            ) // error in android 6: InvalidKeyException: Need RSA private or public key
        } else {
            Cipher.getInstance(
                "RSA/ECB/PKCS1Padding",
                "AndroidKeyStoreBCWorkaround"
            ) // error in android 5: NoSuchProviderException: Provider not available: AndroidKeyStoreBCWorkaround
        }
    }

    @Throws(Exception::class)
    private fun createRSAKeysIfNeeded(keyAlias: String, password: String?) {
        val ks = KeyStore.getInstance(KEYSTORE_PROVIDER_ANDROID)
        ks.load(null)

        // Added hacks for getting KeyEntry:
        // https://stackoverflow.com/questions/36652675/java-security-unrecoverablekeyexception-failed-to-obtain-information-about-priv
        // https://stackoverflow.com/questions/36488219/android-security-keystoreexception-invalid-key-blob
        var privateKey: PrivateKey? = null
        var publicKey: PublicKey? = null
        for (i in 1..5) {
            try {
                privateKey = ks.getKey(keyAlias, password?.toCharArray()) as PrivateKey
                publicKey = ks.getCertificate(keyAlias).publicKey
                break
            } catch (ignored: Exception) {
            }
        }

        if (privateKey == null || publicKey == null) {
            createKeys(keyAlias)
            try {
                privateKey = ks.getKey(keyAlias, password?.toCharArray()) as PrivateKey
                publicKey = ks.getCertificate(keyAlias).publicKey
            } catch (ignored: Exception) {
                ks.deleteEntry(keyAlias)
            }
            if (privateKey == null || publicKey == null) {
                createKeys(keyAlias)
            }
        }
    }

    @SuppressLint("NewApi")
    @Throws(Exception::class)
    private fun createKeys(keyAlias: String) {
        val start = Calendar.getInstance()
        val end = Calendar.getInstance()
        end.add(Calendar.YEAR, 25)

        val kpGenerator =
            KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, KEYSTORE_PROVIDER_ANDROID)

        val spec: AlgorithmParameterSpec

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            spec = android.security.KeyPairGeneratorSpec.Builder(context)
                .setAlias(keyAlias)
                .setSubject(X500Principal("CN=$keyAlias"))
                .setSerialNumber(BigInteger.valueOf(1))
                .setStartDate(start.time)
                .setEndDate(end.time)
                .build()
        } else {
            spec = KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_DECRYPT or KeyProperties.PURPOSE_ENCRYPT
            )
                .setCertificateSubject(X500Principal("CN=$keyAlias"))
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1)
                .setUserAuthenticationValidityDurationSeconds(10)
                .setUserAuthenticationRequired(true)
                .setIsStrongBoxBacked(true)
                .setCertificateSerialNumber(BigInteger.valueOf(1))
                .setCertificateNotBefore(start.time)
                .setCertificateNotAfter(end.time)
                .build()
        }
        kpGenerator.initialize(spec)
        kpGenerator.generateKeyPair()
    }

}

class HardwareEncryptionPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var rsaKeyStoreKey: RsaKeyStoreKey


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.mofalabs.hardware_encryption/hardware_encryption"
        )
        channel.setMethodCallHandler(this)
        rsaKeyStoreKey = RsaKeyStoreKey(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "encrypt" -> {
                val arguments = call.arguments as Map<*, *>
                val data = rsaKeyStoreKey.encrypt(
                    arguments["tag"] as String,
                    arguments["message"] as ByteArray,
                    arguments["password"] as String?,
                )
                result.success(data)
            }
            "decrypt" -> {
                val arguments = call.arguments as Map<*, *>
                val data = rsaKeyStoreKey.decrypt(
                    arguments["tag"] as String,
                    arguments["message"] as ByteArray,
                    arguments["password"] as String?,
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

