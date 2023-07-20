import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'hardware_encryption.dart';

class BiometricUtil {
  static LocalAuthentication auth = LocalAuthentication();

  static Future<bool> checkBiometrics() async {
    bool result = await BiometricUtil.checkAvailableBiometrics();
    if (!result) {
      throw notSetError;
    }

    if (Platform.isAndroid) {
      final List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();
      if (availableBiometrics.contains(BiometricType.strong) ||
          availableBiometrics.contains(BiometricType.face) ||
          availableBiometrics.contains(BiometricType.fingerprint)) {
        result = await auth.authenticate(
          localizedReason: 'App needs to authenticate using faces.',
          options: const AuthenticationOptions(
            biometricOnly: true,
            useErrorDialogs: true,
          ),
        );
      }
    }
    return result;
  }

  static Future<bool> checkAvailableBiometrics() async {
    if (await auth.canCheckBiometrics || await auth.isDeviceSupported()) {
      final List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } else {
      debugPrint('Your device does not support biometrics');
      throw notSupportError;
    }
  }
}