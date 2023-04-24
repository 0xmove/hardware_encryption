import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricUtil {
  static LocalAuthentication auth = LocalAuthentication();

  static Future<bool> checkBiometrics() async {
    bool result = false;
    if (await auth.canCheckBiometrics || await auth.isDeviceSupported()) {
      final List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        debugPrint('Your device does not support biometrics');
      } else if (availableBiometrics.contains(BiometricType.strong) ||
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
    } else {
      debugPrint('Your device does not support biometrics');
    }
    return result;
  }
}
