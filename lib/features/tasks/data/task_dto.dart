import '../domain/task.dart';

class TaskDto {
  static Map<String, dynamic> toJson(Task task) => {
    'id': task.id,
    'title': task.title,
    'priority': task.priority.index,
    'completed': task.completed,
    'createdAt': task.createdAt.toIso8601String(),
  };

  static Task fromJson(Map<dynamic, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    priority: TaskPriority.values[json['priority'] as int],
    completed: json['completed'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

