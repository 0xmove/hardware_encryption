import 'hardware_encryption_platform_interface.dart';

class HardwareEncryption {
  Future<String> encrypt(String tag, String encryptText) async {
    return await HardwareEncryptionPlatform.instance.encrypt(tag, encryptText);
  }

  Future<String> decrypt(String tag, String decryptText) async {
    return await HardwareEncryptionPlatform.instance.decrypt(tag, decryptText);
  }

  Future<bool> removeKey(String tag) async {
    return await HardwareEncryptionPlatform.instance.removeKey(tag);
  }
}
