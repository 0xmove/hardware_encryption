class EncryptionError extends Error {
  final String? message;

  EncryptionError(String this.message);

  @override
  String toString() => "Encryption error: $message";
}
