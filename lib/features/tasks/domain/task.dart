enum TaskPriority { normal, important, urgent }

class Task {
  Task({
    required this.id,
    required String title,
    this.priority = TaskPriority.normal,
    this.completed = false,
    required this.createdAt,
  }) : title = validateTitle(title);

  final String id;
  final String title;
  final TaskPriority priority;
  final bool completed;
  final DateTime createdAt;

  static String validateTitle(String value) {
    final title = value.trim();
    if (title.isEmpty || title.length > 120) {
      throw ArgumentError('Escribe una tarea de 1 a 120 caracteres.');
    }
    return title;
  }

  Task copyWith({String? title, TaskPriority? priority, bool? completed}) =>
      Task(
        id: id,
        title: title ?? this.title,
        priority: priority ?? this.priority,
        completed: completed ?? this.completed,
        createdAt: createdAt,
      );
}

