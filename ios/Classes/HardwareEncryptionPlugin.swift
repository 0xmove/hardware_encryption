import Flutter
import UIKit

public class HardwareEncryptionPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.mofalabs.hardware_encryption/hardware_encryption", binaryMessenger: registrar.messenger())
    let instance = HardwareEncryptionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
