import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricUtil {
  static LocalAuthentication auth = LocalAuthentication();

  static Future<bool> checkDecryptBiometrics() async {
    var result = false;
    try {
      if (Platform.isAndroid) {
        if (await auth.canCheckBiometrics || await auth.isDeviceSupported()) {
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
      } else {
        result = true;
      }
    } catch (e) {
      result = false;
      print(e.toString());
    }
    return result;
  }

  static checkBiometrics(Function()? next) async {
    if (await auth.canCheckBiometrics || await auth.isDeviceSupported()) {
      final List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        debugPrint('Your device does not support biometrics');
      } else if (availableBiometrics.contains(BiometricType.strong) ||
          availableBiometrics.contains(BiometricType.face) ||
          availableBiometrics.contains(BiometricType.fingerprint)) {
        auth
            .authenticate(
          localizedReason: 'App needs to authenticate using faces.',
          options: const AuthenticationOptions(
            biometricOnly: true,
            useErrorDialogs: true,
          ),
        )
            .then((value) {
          value && next?.call();
        }).catchError((e) {
          print(e);
        });
      }
    } else {
      debugPrint('Your device does not support biometrics');
    }
  }
}
