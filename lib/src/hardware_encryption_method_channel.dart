import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'biometric_util.dart';
import 'encryption_error.dart';
import 'hardware_encryption.dart';
import 'hardware_encryption_platform_interface.dart';

/// An implementation of [HardwareSecurityPlatform] that uses method channels.
class MethodChannelHardwareEncryption extends HardwareEncryptionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
      'com.mofalabs.hardware_encryption/hardware_encryption');

  @override
  Future<String> encrypt(String tag, String encryptText) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'encrypt',
      {
        "message": Platform.isAndroid ? utf8.encode(encryptText) : encryptText,
        'tag': tag,
      },
    );
    if (result == null) {
      throw EncryptionError('encrypt fail');
    }
    return base64.encode(result);
  }

  @override
  Future<String> decrypt(String tag, String decryptText) async {
    if (!(await BiometricUtil.checkAvailableBiometrics())) {
      throw notSetError;
    }
    if (Platform.isAndroid) {
      await BiometricUtil.checkBiometrics();
    }
    final result = await methodChannel.invokeMethod<dynamic>(
      'decrypt',
      {
        "message": base64.decode(decryptText),
        'tag': tag,
      },
    );
    if (result == null) {
      throw EncryptionError('decrypt fail');
    }
    return Platform.isAndroid
        ? utf8.decode(result as Uint8List)
        : result.toString();
  }

  @override
  Future<bool> removeKey(String tag) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'removeKey',
      {"tag": tag},
    );
    if (result == null) {
      throw EncryptionError('removeKey fail');
    }
    return result as bool;
  }
}
