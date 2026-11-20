/// A study task the user wants to focus on. Sessions can be linked to a
/// task so history and stats show where the focus time actually went.
class FocusTask {
  FocusTask({
    this.id,
    required this.title,
    this.notes = '',
    this.colorValue = 0xFFEF6C00,
    DateTime? createdAt,
    this.isCompleted = false,
    this.totalFocusSeconds = 0,
    this.completedSessions = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final String title;
  final String notes;
  final int colorValue;
  final DateTime createdAt;
  final bool isCompleted;
  final int totalFocusSeconds;
  final int completedSessions;

  FocusTask copyWith({
    int? id,
    String? title,
    String? notes,
    int? colorValue,
    DateTime? createdAt,
    bool? isCompleted,
    int? totalFocusSeconds,
    int? completedSessions,
  }) {
    return FocusTask(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      totalFocusSeconds: totalFocusSeconds ?? this.totalFocusSeconds,
      completedSessions: completedSessions ?? this.completedSessions,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'color_value': colorValue,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'total_focus_seconds': totalFocusSeconds,
      'completed_sessions': completedSessions,
    };
  }

  factory FocusTask.fromMap(Map<String, Object?> map) {
    return FocusTask(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      colorValue: (map['color_value'] as int?) ?? 0xFFEF6C00,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as int?) ?? 0,
      ),
      isCompleted: ((map['is_completed'] as int?) ?? 0) == 1,
      totalFocusSeconds: (map['total_focus_seconds'] as int?) ?? 0,
      completedSessions: (map['completed_sessions'] as int?) ?? 0,
    );
  }
}
