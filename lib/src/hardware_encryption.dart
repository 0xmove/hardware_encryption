import 'hardware_encryption_platform_interface.dart';

class HardwareEncryption {
  Future<String> encrypt(String tag, String plainText) async {
    return await HardwareEncryptionPlatform.instance.encrypt(tag, plainText);
  }

  Future<String> decrypt(String tag, String cipherText) async {
    return await HardwareEncryptionPlatform.instance.decrypt(tag, cipherText);
  }

  Future<bool> removeKey(String tag) async {
    return await HardwareEncryptionPlatform.instance.removeKey(tag);
  }
}