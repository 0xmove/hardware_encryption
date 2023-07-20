import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'hardware_encryption_platform_interface.dart';

/// An implementation of [HardwareEncryptionPlatform] that uses method channels.
class MethodChannelHardwareEncryption extends HardwareEncryptionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('hardware_encryption');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
