import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'hardware_encryption_method_channel.dart';

abstract class HardwareEncryptionPlatform extends PlatformInterface {
  /// Constructs a HardwareEncryptionPlatform.
  HardwareEncryptionPlatform() : super(token: _token);

  static final Object _token = Object();

  static HardwareEncryptionPlatform _instance =
      MethodChannelHardwareEncryption();

  /// The default instance of [HardwareEncryptionPlatform] to use.
  ///
  /// Defaults to [MethodChannelHardwareSecurity].
  static HardwareEncryptionPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HardwareEncryptionPlatform] when
  /// they register themselves.
  static set instance(HardwareEncryptionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> encrypt(String tag, String encryptText) async {
    throw UnimplementedError('function encrypt has not been implemented.');
  }

  Future<String> decrypt(String tag, String decryptText) async {
    throw UnimplementedError('function decrypt has not been implemented.');
  }

  Future<bool> removeKey(String tag) async {
    throw UnimplementedError('function removeKey has not been implemented.');
  }
}
