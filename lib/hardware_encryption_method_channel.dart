import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'hardware_encryption_platform_interface.dart';

/// An implementation of [HardwareSecurityPlatform] that uses method channels.
class MethodChannelHardwareEncryption extends HardwareEncryptionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
      'com.mofalabs.hardware_encryption/hardware_encryption');

  Future<String> encrypt(String tag, String encryptText) async {
    if (Platform.isAndroid) {
      final result = await methodChannel.invokeMethod<Uint8List>(
        'encrypt',
        {"message":  utf8.encode(encryptText), 'tag': tag},
      );
      return base64.encode(result as Uint8List);
    } else {
      final result = await methodChannel.invokeMethod<dynamic>(
        'encrypt',
        {"message": encryptText, 'tag': tag},
      );
      return base64.encode(result as Uint8List);
    }
  }

  Future<String> decrypt(String tag, String decryptText) async {
    if (Platform.isAndroid) {
      final result = await methodChannel.invokeMethod<Uint8List>(
        'decrypt',
        {"message":  base64.decode(decryptText), 'tag': tag},
      );
      return utf8.decode(result as Uint8List);
    } else {
      final result = await methodChannel.invokeMethod<dynamic>(
        'decrypt',
        {"message": base64.decode(decryptText), 'tag': tag},
      );
      return result.toString();
    }
  }

  Future<bool> removeKey(String tag) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'removeKey',
      {
        "tag": tag,
      },
    );
    return result as bool;
  }
}
