import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hardware_encryption/hardware_encryption.dart';
import 'package:local_auth/local_auth.dart';

class BiometricUtil {
  static final LocalAuthentication auth = LocalAuthentication();

  /// Authenticates the user using biometric authentication on Android devices.
  /// 
  /// [localizedReason] The message to show to user when requesting biometric authentication.
  /// If not provided, uses a default message.
  /// 
  /// Returns `true` if authentication was successful, `false` otherwise.
  /// 
  /// Throws:
  /// * [PlatformException] when platform is not Android
  /// * [BiometricsNotSetException] when biometrics are not available or not enrolled
  static Future<bool> authenticateAndroid({String? localizedReason}) async {
    if (!Platform.isAndroid) {
      throw PlatformException(
        code: 'platform_not_supported',
        message: 'Platform not supported',
      );
    }

    bool result = await isBiometricAvailable();
    if (!result) {
      throw BiometricsNotSetException();
    }

    final List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();
    if (availableBiometrics.contains(BiometricType.strong) ||
        availableBiometrics.contains(BiometricType.face) ||
        availableBiometrics.contains(BiometricType.fingerprint)) {
      result = await auth.authenticate(
        localizedReason: localizedReason ?? 'App needs to authenticate to continue.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    }

    return result;
  }

  /// Checks if biometric authentication is available on the device.
  /// 
  /// Returns `true` if:
  /// * The device has biometric capabilities
  /// * At least one biometric method is enrolled
  /// 
  /// Returns `false` if:
  /// * Biometrics are not available
  /// * No biometrics are enrolled
  static Future<bool> isBiometricAvailable() async {
    if (!(await auth.canCheckBiometrics)) {
      return false;
    }

    final List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();
    return availableBiometrics.isNotEmpty;
  }

  /// Checks if any form of local authentication is supported on the device.
  /// 
  /// Supported authentication methods include:
  /// * Biometrics (fingerprint, face, iris)
  /// * PIN
  /// * Pattern
  /// * Password
  /// 
  /// Returns `true` if the device supports any form of local authentication,
  /// `false` otherwise.
  static Future<bool> isAuthenticationAvailable() async {
    return await auth.isDeviceSupported();
  }

  /// Retrieves a list of enrolled biometric types available on the device.
  /// 
  /// Possible biometric types include:
  /// * [BiometricType.fingerprint]
  /// * [BiometricType.face]
  /// * [BiometricType.iris]
  /// * [BiometricType.strong]
  /// 
  /// Returns an empty list if:
  /// * Biometrics are not supported
  /// * No biometrics are enrolled
  /// 
  /// This method does not throw exceptions.
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    if (!(await auth.canCheckBiometrics)) {
      return [];
    }
    return await auth.getAvailableBiometrics();
  }
}