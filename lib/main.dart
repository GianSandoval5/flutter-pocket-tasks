import 'package:material_ui/material_ui.dart';
import 'dart:async';

import 'package:http/http.dart' as http;

import 'core/api_config.dart';
import 'features/tasks/data/mobilelab_task_repository.dart';
import 'features/tasks/domain/task.dart';
import 'features/tasks/presentation/task_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = MobileLabTaskRepository(
    client: http.Client(),
    baseUri: ApiConfig.baseUri,
  );
  final controller = TaskController(repository);
  runApp(PocketTasksApp(controller: controller));
  unawaited(controller.load());
}

class PocketTasksApp extends StatelessWidget {
  const PocketTasksApp({super.key, required this.controller});
  final TaskController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pocket Tasks',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245E57)),
    ),
    home: TasksHome(controller: controller),
  );
}

class TasksHome extends StatefulWidget {
  const TasksHome({super.key, required this.controller});
  final TaskController controller;
  @override
  State<TasksHome> createState() => _TasksHomeState();
}

class _TasksHomeState extends State<TasksHome> {
  int page = 0;
  bool completed = false;
  String query = '';
  final labels = ['Normal', 'Importante', 'Urgente'];

  Future<void> edit([Task? existing]) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => TaskEditor(existing: existing),
    );
    if (result != null) await widget.controller.save(result);
  }

  Future<void> confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar tarea?'),
        content: Text(task.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.delete(task);
  }

  Widget tasks(TaskController controller) {
    final items = controller.filtered(query: query, completed: completed);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() {
                  query = value;
                }),
                decoration: const InputDecoration(
                  labelText: 'Buscar tareas',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Pendientes')),
                  ButtonSegment(value: true, label: Text('Completadas')),
                ],
                selected: {completed},
                onSelectionChanged: (values) => setState(() {
                  completed = values.first;
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      query.isNotEmpty
                          ? 'No hay coincidencias.'
                          : completed
                          ? 'Tus tareas completadas aparecerán aquí.'
                          : 'Tu siguiente paso empieza con una tarea.',
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final task = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.completed,
                          onChanged: controller.busy
                              ? null
                              : (_) => controller.toggle(task),
                        ),
                        title: Text(task.title),
                        subtitle: Text(labels[task.priority.index]),
                        onTap: controller.busy ? null : () => edit(task),
                        trailing: IconButton(
                          tooltip: 'Eliminar ${task.title}',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: controller.busy
                              ? null
                              : () => confirmDelete(task),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget summary(TaskController controller) {
    final total = controller.tasks.length;
    final done = controller.completedCount;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Un paso a la vez',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Tus tareas se guardan en la base SQLite de MobileLab.'),
        const SizedBox(height: 32),
        LinearProgressIndicator(
          value: total == 0 ? 0 : done / total,
          minHeight: 12,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: const Text('Completadas'),
          trailing: Text('$done'),
        ),
        ListTile(
          leading: const Icon(Icons.pending_actions),
          title: const Text('Pendientes'),
          trailing: Text('${total - done}'),
        ),
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Urgentes pendientes'),
          trailing: Text(
            '${controller.tasks.where((task) => !task.completed && task.priority == TaskPriority.urgent).length}',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      return Scaffold(
        appBar: AppBar(title: const Text('Pocket Tasks')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Column(
                children: [
                  if (controller.busy) const LinearProgressIndicator(),
                  if (controller.error != null)
                    MaterialBanner(
                      content: Text(controller.error!),
                      actions: [
                        TextButton(
                          onPressed: controller.busy ? null : controller.load,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: page == 0
                        ? tasks(controller)
                        : page == 1
                        ? summary(controller)
                        : ListView(
                            padding: const EdgeInsets.all(24),
                            children: const [
                              Icon(Icons.offline_bolt_outlined, size: 64),
                              SizedBox(height: 24),
                              Text(
                                'Tu app. Tu sandbox.',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Crea, edita y organiza tus tareas mediante MobileLab. Los datos viven en su base SQLite y permanecen al reiniciar el servicio.',
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Inicia MobileLab en tu ordenador antes de usar la app. La configuración incluida es un sandbox local de desarrollo, sin cuentas ni sincronización cloud.',
                              ),
                              SizedBox(height: 32),
                              Text(
                                'Gian Sandoval',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text('Arquitecto Mobile'),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: page == 0
            ? FloatingActionButton.extended(
                onPressed: controller.busy ? null : () => edit(),
                icon: const Icon(Icons.add),
                label: const Text('Nueva tarea'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: (value) => setState(() {
            page = value;
          }),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.checklist), label: 'Tareas'),
            NavigationDestination(icon: Icon(Icons.insights), label: 'Resumen'),
            NavigationDestination(
              icon: Icon(Icons.info_outline),
              label: 'Acerca de',
            ),
          ],
        ),
      );
    },
  );
}

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.existing});
  final Task? existing;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title;
  late TaskPriority priority;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.existing?.title ?? '');
    priority = widget.existing?.priority ?? TaskPriority.normal;
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Nueva tarea' : 'Editar tarea'),
    content: SizedBox(
      width: 400,
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: title,
              autofocus: true,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: '¿Qué quieres hacer?',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe una tarea.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'Prioridad'),
              items: TaskPriority.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        const ['Normal', 'Importante', 'Urgente'][value.index],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                priority = value!;
              }),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          final existing = widget.existing;
          final now = DateTime.now();
          Navigator.pop(
            context,
            Task(
              id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
              title: title.text,
              priority: priority,
              completed: existing?.completed ?? false,
              createdAt: existing?.createdAt ?? now,
            ),
          );
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}

