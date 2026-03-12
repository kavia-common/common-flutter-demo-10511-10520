package com.example.common_flutter_demo

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.common_flutter_demo/device_security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSecurityStatus" -> {
                        try {
                            result.success(getSecurityStatus())
                        } catch (e: Exception) {
                            result.error("SECURITY_STATUS_ERROR", e.message, null)
                        }
                    }

                    "authenticate" -> {
                        val reason: String = call.argument<String>("reason") ?: "Authenticate"
                        val allowDeviceCredential: Boolean =
                            call.argument<Boolean>("allowDeviceCredential") ?: true

                        authenticate(
                            reason = reason,
                            allowDeviceCredential = allowDeviceCredential,
                            result = result
                        )
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun getSecurityStatus(): Map<String, Any> {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val isDeviceSecure = keyguardManager.isDeviceSecure

        val biometricManager = BiometricManager.from(this)

        val canBiometricStrong = canAuthenticateCompat(
            biometricManager,
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        )

        val canDeviceCredential = canAuthenticateCompat(
            biometricManager,
            BiometricManager.Authenticators.DEVICE_CREDENTIAL
        )

        val canStrongOrCredential = canAuthenticateCompat(
            biometricManager,
            BiometricManager.Authenticators.BIOMETRIC_STRONG or
                BiometricManager.Authenticators.DEVICE_CREDENTIAL
        )

        return mapOf(
            "isDeviceSecure" to isDeviceSecure,
            "canBiometricStrong" to canBiometricStrong,
            "canDeviceCredential" to canDeviceCredential,
            "canStrongOrCredential" to canStrongOrCredential,
        )
    }

    private fun canAuthenticateCompat(
        biometricManager: BiometricManager,
        authenticators: Int
    ): Boolean {
        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            biometricManager.canAuthenticate(authenticators)
        } else {
            @Suppress("DEPRECATION")
            biometricManager.canAuthenticate()
        }

        return code == BiometricManager.BIOMETRIC_SUCCESS
    }

    private fun authenticate(
        reason: String,
        allowDeviceCredential: Boolean,
        result: MethodChannel.Result
    ) {
        val executor = ContextCompat.getMainExecutor(this)

        val prompt = BiometricPrompt(
            this,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(authResult)
                    result.success(
                        mapOf(
                            "status" to "success",
                            "errorCode" to null,
                            "errorMessage" to null,
                        )
                    )
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    // Non-fatal; user can retry. Report as "failed" to UI.
                    result.success(
                        mapOf(
                            "status" to "failed",
                            "errorCode" to null,
                            "errorMessage" to "Authentication failed",
                        )
                    )
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    val status = if (errorCode == BiometricPrompt.ERROR_NEGATIVE_BUTTON ||
                        errorCode == BiometricPrompt.ERROR_USER_CANCELED ||
                        errorCode == BiometricPrompt.ERROR_CANCELED
                    ) {
                        "canceled"
                    } else {
                        "error"
                    }

                    result.success(
                        mapOf(
                            "status" to status,
                            "errorCode" to errorCode,
                            "errorMessage" to errString.toString(),
                        )
                    )
                }
            }
        )

        val promptInfo = buildPromptInfo(
            title = reason,
            allowDeviceCredential = allowDeviceCredential
        )

        prompt.authenticate(promptInfo)
    }

    private fun buildPromptInfo(title: String, allowDeviceCredential: Boolean): BiometricPrompt.PromptInfo {
        val builder = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setSubtitle("Confirm your identity")
            .setDescription("Use biometrics or device credential to continue.")

        if (allowDeviceCredential) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                builder.setAllowedAuthenticators(
                    BiometricManager.Authenticators.BIOMETRIC_STRONG or
                        BiometricManager.Authenticators.DEVICE_CREDENTIAL
                )
            } else {
                @Suppress("DEPRECATION")
                builder.setDeviceCredentialAllowed(true)
            }
        } else {
            builder.setNegativeButtonText("Cancel")
        }

        return builder.build()
    }
}
