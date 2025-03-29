import 'package:flutter/services.dart';

class EncryptionException implements Exception {
  final String message;

  const EncryptionException(this.message);

  @override
  String toString() => message;
}

class BiometricsNotSetException extends PlatformException {
  BiometricsNotSetException()
      : super(code: 'biometrics_not_set', message: 'Biometrics not set');
}

class BiometricsNotSupportedException extends PlatformException {
  BiometricsNotSupportedException() : super(code: 'biometrics_not_supported', message: 'Biometrics not supported');
}

class BiometricsAuthenticationException extends PlatformException {
  BiometricsAuthenticationException() : super(code: 'biometrics_authentication_failed', message: 'Biometrics authentication failed');
}
