import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'biometric_util.dart';
import 'hardware_encryption_platform_interface.dart';

/// An implementation of [HardwareSecurityPlatform] that uses method channels.
class MethodChannelHardwareEncryption extends HardwareEncryptionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
      'com.mofalabs.hardware_encryption/hardware_encryption');

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

  Future<String> decrypt(String tag, String decryptText) async {
    if(await BiometricUtil.checkDecryptBiometrics()){
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
    } else {
      throw EncryptionError('check biometrics fail');
    }
  }

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

@pragma("vm:entry-point")
class EncryptionError extends Error {
  final String? message;

  @pragma("vm:entry-point")
  EncryptionError(String this.message);

  String toString() => "Encryption operation: $message";
}
