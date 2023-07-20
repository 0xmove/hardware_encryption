import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'hardware_encryption_method_channel.dart';

abstract class HardwareEncryptionPlatform extends PlatformInterface {
  /// Constructs a HardwareEncryptionPlatform.
  HardwareEncryptionPlatform() : super(token: _token);

  static final Object _token = Object();

  static HardwareEncryptionPlatform _instance = MethodChannelHardwareEncryption();

  /// The default instance of [HardwareEncryptionPlatform] to use.
  ///
  /// Defaults to [MethodChannelHardwareEncryption].
  static HardwareEncryptionPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HardwareEncryptionPlatform] when
  /// they register themselves.
  static set instance(HardwareEncryptionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
