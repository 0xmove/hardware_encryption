import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'hardware_encryption_platform_interface.dart';

/// An implementation of [HardwareSecurityPlatform] that uses method channels.
class MethodChannelHardwareEncryption extends HardwareEncryptionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
      'com.mofalabs.hardware_encryption/hardware_encryption');

  Future<String> encrypt(String encryptText) async {
    final result = await methodChannel.invokeMethod<Uint8List>(
        'encrypt', utf8.encode(encryptText));
    return base64.encode(result as Uint8List);
  }

  Future<String> decrypt(String decryptText) async {
    final result = await methodChannel.invokeMethod<List<int>>(
        'decrypt', base64.decode(decryptText));
    return utf8.decode(result as Uint8List);
  }
}
