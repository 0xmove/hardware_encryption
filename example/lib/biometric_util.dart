import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricUtil {
  static LocalAuthentication auth = LocalAuthentication();

  static checkBiometrics(Function() next) async {
    if (Platform.isAndroid) {
      if (await auth.canCheckBiometrics || await auth.isDeviceSupported()) {
        final List<BiometricType> availableBiometrics =
            await auth.getAvailableBiometrics();
        if (availableBiometrics.isEmpty) {
          debugPrint('Your device does not support biometrics');
        } else {
          if (availableBiometrics.contains(BiometricType.strong) ||
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
              if (value) {
                next();
              }
            }).catchError((error) {
              // user refuse to auth
              print(error);
            });
          }
        }
      } else {
        debugPrint('Your device does not support biometrics');
      }
    } else {
      next();
    }
  }
}
