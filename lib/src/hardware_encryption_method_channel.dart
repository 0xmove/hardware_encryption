import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'biometric_util.dart';
import 'exceptions.dart';
import 'hardware_encryption_platform_interface.dart';

/// An implementation of [HardwareSecurityPlatform] that uses method channels.
class MethodChannelHardwareEncryption extends HardwareEncryptionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
      'com.mofalabs.hardware_encryption/hardware_encryption');

  @override
  Future<String> encrypt(String tag, String plainText) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'encrypt',
      {
        "message": Platform.isAndroid ? utf8.encode(plainText) : plainText,
        'tag': tag,
      },
    );
    if (result == null) {
      throw const EncryptionException('Failed to encrypt data');
    }
    return base64.encode(result);
  }

  @override
  Future<String> decrypt(String tag, String cipherText) async {
    if (Platform.isIOS && !(await BiometricUtil.isBiometricAvailable())) {
      throw BiometricsNotSetException();
    }

    // Android biometric authentication is required before decrypting the cipher text
    if (Platform.isAndroid && !(await BiometricUtil.authenticateAndroid())) {
      throw BiometricsAuthenticationException();
    }

    final result = await methodChannel.invokeMethod<dynamic>(
      'decrypt',
      {
        "message": base64.decode(cipherText),
        'tag': tag,
      },
    );
    if (result == null) {
      throw const EncryptionException('Failed to decrypt data');
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
      throw EncryptionException('Failed to remove key $tag');
    }
    return result as bool;
  }
}
