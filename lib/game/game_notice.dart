enum NoticeKind { info, success, error }

/// A short message shown in the alert stack (top right).
class GameNotice {
  static int _nextId = 0;

  final int id;
  final NoticeKind kind;
  final String title;
  final String message;

  /// Seed for a person's avatar, if the notice is about someone.
  final String? avatarSeed;

  /// How long the notice stays. Null = until dismissed.
  final Duration? lifetime;

  GameNotice({
    required this.kind,
    required this.title,
    this.message = '',
    this.avatarSeed,
    this.lifetime = const Duration(seconds: 4),
  }) : id = _nextId++;
}
