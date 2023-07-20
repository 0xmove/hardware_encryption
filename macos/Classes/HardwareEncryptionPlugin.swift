import Cocoa
import FlutterMacOS
import LocalAuthentication

public class HardwareEncryptionPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.mofalabs.hardware_encryption/hardware_encryption", binaryMessenger: registrar.messenger)
        let instance = HardwareEncryptionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "encrypt":
            do {
                let param = call.arguments as? Dictionary<String, Any>
                let message = param!["message"] as! String
                let tag = param!["tag"] as! String
                var password: String? = nil
                if let pwd = param!["password"] as? String {
                    password = pwd
                }
                let encrypted = try encrypt(message: message, tag: tag, password: password)
                result(encrypted)
            } catch {
                result(nil)
            }
        case "decrypt":
            do {
                let param = call.arguments as? Dictionary<String, Any>
                let message = param!["message"] as! FlutterStandardTypedData
                let tag = param!["tag"] as! String
                var password : String? = nil
                if let pwd = param!["password"] as? String {
                    password = pwd
                }
                let decrypted = try decrypt(message: message.data, tag: tag, password: password)
                result(decrypted)
            } catch {
                result(nil)
            }
        case "removeKey":
            do {
                let param = call.arguments as? Dictionary<String, Any>
                let tag = param!["tag"] as! String
                let isSuccess = try removeKey(tag: tag)
                result(isSuccess)
            } catch {
                result(nil)
            }
        default:
            result(nil)
        }
    }
    
    internal func generateKeyPair(tag: String, password: String?) throws -> SecKey  {
        var accessError: Unmanaged<CFError>?
        guard let secAttrAccessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.biometryAny,
             .privateKeyUsage],
            &accessError) else {
            throw accessError!.takeRetainedValue() as Error
        }
        
        guard let secAttrApplicationTag = tag.data(using: .utf8) else {
            throw CustomError.runtimeError("Invalid TAG") as Error
        }
        
        var parameters: Dictionary<String, Any>
        parameters = [
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String     : 256,
            kSecAttrTokenID as String           : kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String : [
                kSecAttrIsPermanent as String       : true,
                kSecAttrApplicationTag as String    : secAttrApplicationTag,
                kSecAttrAccessControl as String     : secAttrAccessControl
            ]
        ]
        
        if let password = password {
            var newPassword: Data?
            if !password.isEmpty {
                newPassword = password.data(using: .utf8)
            }
            
            let context = LAContext()
            context.setCredential(newPassword, type: .applicationPassword)
            parameters[kSecUseAuthenticationContext as String] = context
        }
        
        var secKeyCreateRandomKeyError: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateRandomKey(parameters as CFDictionary, &secKeyCreateRandomKeyError) else {
            throw secKeyCreateRandomKeyError!.takeRetainedValue() as Error
        }
        
        return secKey
    }
    
    internal func getSecKey(tag: String, password: String?, createIfNeed: Bool) throws -> SecKey?  {
        let secAttrApplicationTag = tag.data(using: .utf8)!
        var query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : secAttrApplicationTag,
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecMatchLimit as String            : kSecMatchLimitOne,
            kSecReturnRef as String             : true
        ]
        if let password = password {
            var newPassword: Data?
            if !password.isEmpty {
                newPassword = password.data(using: .utf8)
            }
            
            let context = LAContext()
            context.setCredential(newPassword, type: .applicationPassword)
            query[kSecUseAuthenticationContext as String] = context
        }
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status != errSecSuccess && createIfNeed {
            item = try generateKeyPair(tag: tag, password: password)
        }
        
        if let item = item {
            return (item as! SecKey)
        } else {
            return nil
        }
    }
    
    internal func encrypt(message: String, tag: String, password: String?) throws -> FlutterStandardTypedData?  {
        let secKey: SecKey
        let publicKey: SecKey
        
        do {
            secKey = try getSecKey(tag: tag, password: password, createIfNeed: true)!
            publicKey = SecKeyCopyPublicKey(secKey)!
        } catch {
            throw error
        }
        
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw CustomError.runtimeError("Encrypt algorithm not suppoort")
        }
        
        var error: Unmanaged<CFError>?
        let plainTextData = message.data(using: .utf8)!
        guard let cipherTextData = SecKeyCreateEncryptedData(
            publicKey,
            algorithm,
            plainTextData as CFData,
            &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        
        return FlutterStandardTypedData(bytes: cipherTextData)
    }
    
    internal func decrypt(message: Data, tag: String, password: String?) throws -> String?  {
        let secKey: SecKey
        
        do {
            if let secKeyTmp = try getSecKey(tag: tag, password: password, createIfNeed: false) {
                secKey = secKeyTmp
            } else {
                throw CustomError.runtimeError("SecKey not found")
            }
        } catch {
            throw error
        }
        
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        let cipherTextData = message as CFData
        
        guard SecKeyIsAlgorithmSupported(secKey, .decrypt, algorithm) else {
            throw CustomError.runtimeError("Decrypt algorithm not supported")
        }
        
        var error: Unmanaged<CFError>?
        guard let plainTextData = SecKeyCreateDecryptedData(
            secKey,
            algorithm,
            cipherTextData,
            &error) as Data? else {
            throw error!.takeUnretainedValue() as Error
        }

        let plainText = String(decoding: plainTextData, as: UTF8.self)
        return plainText
    }
    
    internal func removeKey(tag: String) throws -> Bool {
        let secAttrApplicationTag: Data = tag.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : secAttrApplicationTag
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            if status == errSecNotAvailable || status == errSecItemNotFound {
                return false
            } else {
                throw  NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(status,nil) ?? "Undefined error"])
            }
        }
        
        return true
    }
}

enum CustomError: Error {
    case runtimeError(String)
    
    func get() -> String {
        switch self {
        case .runtimeError(let desc):
            return desc
        }
    }
}
