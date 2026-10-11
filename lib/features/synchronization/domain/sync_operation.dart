/// One pending local change, in the format agreed with the API:
/// `{"entity": "profile", "operation": "UPDATE", "timestamp": "...", "payload": {}}`
class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.entity,
    required this.operation,
    required this.timestamp,
    required this.payload,
    required this.userId,
    this.attempts = 0,
  });

  final String id;
  final String entity;
  final String operation;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final String userId;
  final int attempts;

  /// Credential operations are replayed against /api/auth, not /api/sync.
  bool get isCredential => entity == SyncEntity.user || entity == SyncEntity.session;

  SyncOperation retried() => SyncOperation(
    id: id,
    entity: entity,
    operation: operation,
    timestamp: timestamp,
    payload: payload,
    userId: userId,
    attempts: attempts + 1,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'entity': entity,
    'operation': operation,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'payload': payload,
    'userId': userId,
    'attempts': attempts,
  };

  /// Wire format sent to the server (no client bookkeeping fields).
  Map<String, dynamic> toWire() => {
    'id': id,
    'entity': entity,
    'operation': operation,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'payload': payload,
  };

  factory SyncOperation.fromJson(Map<dynamic, dynamic> json) => SyncOperation(
    id: json['id'] as String,
    entity: json['entity'] as String,
    operation: json['operation'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    userId: json['userId'] as String,
    attempts: (json['attempts'] as int?) ?? 0,
  );
}

abstract final class SyncEntity {
  static const user = 'user';
  static const session = 'session';
  static const profile = 'profile';
  static const application = 'application';
  static const progressEvent = 'progress_event';
  static const badge = 'badge';
  static const favorite = 'favorite';
  static const document = 'document';
}

abstract final class SyncOp {
  static const create = 'CREATE';
  static const update = 'UPDATE';
  static const delete = 'DELETE';
  static const register = 'REGISTER';
  static const login = 'LOGIN';
}
