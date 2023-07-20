import 'package:flutter_test/flutter_test.dart';
import 'package:hardware_encryption/hardware_encryption.dart';
import 'package:hardware_encryption/hardware_encryption_platform_interface.dart';
import 'package:hardware_encryption/hardware_encryption_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHardwareEncryptionPlatform
    with MockPlatformInterfaceMixin
    implements HardwareEncryptionPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final HardwareEncryptionPlatform initialPlatform = HardwareEncryptionPlatform.instance;

  test('$MethodChannelHardwareEncryption is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHardwareEncryption>());
  });

  test('getPlatformVersion', () async {
    HardwareEncryption hardwareEncryptionPlugin = HardwareEncryption();
    MockHardwareEncryptionPlatform fakePlatform = MockHardwareEncryptionPlatform();
    HardwareEncryptionPlatform.instance = fakePlatform;

    expect(await hardwareEncryptionPlugin.getPlatformVersion(), '42');
  });
}
