import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_tasks/features/tasks/presentation/task_controller.dart';
import 'package:pocket_tasks/main.dart';

import '../support/memory_task_repository.dart';

void main() {
  testWidgets('creates and completes a task through the interface', (
    tester,
  ) async {
    final controller = TaskController(MemoryTaskRepository());
    addTearDown(controller.dispose);
    await tester.pumpWidget(PocketTasksApp(controller: controller));
    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Revisar arquitectura');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar arquitectura'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(controller.completedCount, 1);
    await tester.tap(find.text('Completadas'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar arquitectura'), findsOneWidget);
    await tester.tap(find.text('Resumen'));
    await tester.pumpAndSettle();
    expect(find.text('Un paso a la vez'), findsOneWidget);
  });

  testWidgets('rejects empty titles in the task form', (tester) async {
    final controller = TaskController(MemoryTaskRepository());
    addTearDown(controller.dispose);
    await tester.pumpWidget(PocketTasksApp(controller: controller));
    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe una tarea.'), findsOneWidget);
    expect(controller.tasks, isEmpty);
  });
}

