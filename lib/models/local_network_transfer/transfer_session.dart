class TransferSession {
  final String sessionId;
  String status; // e.g., 'pending', 'in_progress', 'completed', 'error'
  double progress;
  String? error;
  String? senderAlias; // Alias of the sending device

  // Add more fields as needed (e.g., startTime, endTime, files, etc.)

  TransferSession({
    required this.sessionId,
    this.status = 'pending',
    this.progress = 0.0,
    this.error,
    this.senderAlias,
  });
} 