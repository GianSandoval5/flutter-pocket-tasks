# Pocket Tasks

Un gestor de tareas personal que funciona sin conexión. Crea tareas, cambia su prioridad, busca, edita, completa y elimina. Consulta un resumen de progreso y conserva tus datos al cerrar la aplicación.

**Gian Sandoval · Arquitecto Mobile**

## Funcionalidades

- Vista de pendientes y completadas, búsqueda y orden por prioridad.
- Formulario con validación, edición y confirmación de eliminación.
- Resumen de tareas completadas, pendientes y urgentes.
- Persistencia real en Hive; sin cuenta ni dependencia de servicios remotos.
- Material 3, navegación por tres secciones y ancho de lectura adaptable.
- Estado de escritura, errores y reintentos.

## Stack y requisitos

Flutter 3.50 o superior compatible y Dart >=3.13. Material UI 1.11.1, Hive 2.2.3 y hive_flutter 1.1.0. Estado con ChangeNotifier e inyección por constructor, sin generadores de código.

Instala Flutter y ejecuta `flutter doctor`. Para Android necesitas Android SDK y JDK 17. Para iOS necesitas macOS y Xcode. El archivo `pubspec.lock` fija las versiones resueltas; `FACTORY_PROVENANCE.json` registra la versión exacta del SDK y las comprobaciones de la publicación inicial.

## Ejecutar desde cero

```bash
git clone https://github.com/GianSandoval5/flutter-pocket-tasks.git
cd flutter-pocket-tasks
flutter pub get
flutter devices
flutter run
# Alternativa para navegador:
flutter run -d chrome
```

## Verificaciones

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build apk --debug
```

El APK se genera en `build/app/outputs/flutter-apk/app-debug.apk` y GitHub Actions lo adjunta como artefacto. La cobertura está en `coverage/lcov.info`; el porcentaje de publicación inicial figura como líneas cubiertas/líneas medidas en `FACTORY_PROVENANCE.json`. No se exige ni se afirma una cobertura del 100%.

Las pruebas cubren validación y edición del dominio, serialización, persistencia tras reabrir Hive, actualización sin duplicados, eliminación, filtros, prioridades, manejo de errores y dos recorridos de la interfaz. Las pruebas de Hive usan directorios temporales aislados.

## Arquitectura

```text
lib/
  main.dart                          # Inicialización e inyección
  features/tasks/
    domain/                          # Task y contrato TaskRepository
    data/                            # DTO e implementación Hive
    presentation/                    # Estado y operaciones de la pantalla
test/
  unit/                              # Dominio, estado y persistencia
  widget/                            # Interacciones de usuario
  support/                           # Repositorio en memoria para tests
```

La presentación depende del contrato `TaskRepository`. La implementación local serializa mapas con `TaskDto`; los identificadores se mantienen al editar. Los cambios se reflejan en memoria después de una escritura exitosa. La UI vive en `main.dart` por el tamaño de este ejemplo; puede extraerse por pantalla al crecer.

## Almacenamiento local

La caja se llama `pocket_tasks_v1`. La inicialización usa el directorio de aplicación proporcionado por hive_flutter; en web usa el almacenamiento soportado por Hive en el navegador. Las tareas no se envían a un servidor ni están cifradas por la aplicación.

Para reiniciar los datos desde código de desarrollo, cierra el repositorio y ejecuta `await Hive.deleteBoxFromDisk('pocket_tasks_v1')` antes de volver a abrirlo. También puedes borrar los datos de la app desde el sistema; en web, borrar el almacenamiento del sitio. Desinstalar o borrar datos elimina la información local.

## Conectar un backend

1. Implementa `TaskRepository` en una clase `ApiTaskRepository`, inyectando un cliente HTTP y la URL base desde la configuración.
2. Mapea los DTOs en esa implementación: `load()` → `GET /tasks`, `save()` → `PUT /tasks/{id}`, `delete()` → `DELETE /tasks/{id}`. Son contratos propuestos, no endpoints existentes.
3. Sustituye `HiveTaskRepository(box)` por la implementación remota al crear `TaskController` en `main.dart`.
4. Añade autenticación en la capa de datos, tiempos de espera, tratamiento de códigos HTTP y pruebas con un cliente simulado. Guarda tokens en almacenamiento seguro apropiado, no en esta caja de tareas.
5. Si quieres conservar el uso offline, implementa un repositorio compuesto Hive/API con cola de cambios y una estrategia explícita de conflictos; sustituir el repositorio por HTTP por sí solo no añade sincronización.

Ejemplo de representación JSON:

```json
{"id":"task-1","title":"Leer 20 minutos","priority":1,"completed":false,"createdAt":"2026-11-17T12:00:00.000Z"}
```

## Alcance y siguientes pasos

No incluye backend, autenticación, sincronización, notificaciones ni copias de seguridad. Se compila Android debug en CI; las carpetas iOS y web se generan con Flutter, pero esta publicación no certifica una compilación iOS ni pruebas de navegador. El APK usa configuración de desarrollo y no está listo para publicar en tiendas.

Siguientes mejoras: fechas y recordatorios locales, exportación/importación, etiquetas y extracción de widgets por pantalla. No se incluyen capturas ficticias: puedes obtenerlas ejecutando la aplicación.

## Licencia

Código original bajo MIT. Los paquetes conservan sus licencias, recogidas en `THIRD_PARTY_NOTICES.md`. Los recursos de plataforma provienen de las plantillas del SDK Flutter.


## Conecta con Gian Sandoval

Si este proyecto te sirve, deja una ⭐ en el repositorio para apoyar la serie de proyectos abiertos.

- GitHub: https://github.com/GianSandoval5
- LinkedIn: https://www.linkedin.com/in/giansandoval/
- Web: https://giansandoval.com

**Gian Sandoval — Arquitecto Mobile**
