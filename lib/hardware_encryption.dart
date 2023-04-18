import 'hardware_encryption_platform_interface.dart';

class HardwareEncryption {
  Future<String> encrypt(String encryptText) async {
    return await HardwareEncryptionPlatform.instance.encrypt(encryptText);
  }

  Future<String> decrypt(String decryptText) async {
    return await HardwareEncryptionPlatform.instance.decrypt(decryptText);
  }
}
