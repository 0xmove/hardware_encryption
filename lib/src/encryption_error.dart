@pragma("vm:entry-point")
class EncryptionError extends Error {
  final String? message;

  @pragma("vm:entry-point")
  EncryptionError(String this.message);

  @override
  String toString() => "Encryption error: $message";
}
