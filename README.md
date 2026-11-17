<!-- mobile-factory:hero -->
<div align="center">
  <img src="docs/assets/pocket-tasks.svg" alt="Pocket Tasks" width="112">
  <h1>Pocket Tasks</h1>
  <p><strong>Tu próxima tarea. Tu propio sandbox.</strong></p>
  <p>Flutter + MobileLab Data API · persistencia real en SQLite.</p>
  <p>
    <a href="https://github.com/GianSandoval5/flutter-pocket-tasks/actions/workflows/ci.yml"><img alt="Flutter CI" src="https://github.com/GianSandoval5/flutter-pocket-tasks/actions/workflows/ci.yml/badge.svg?branch=main"></a>
    <a href="pubspec.yaml"><img alt="Flutter 3.50+" src="https://img.shields.io/badge/Flutter-3.50%2B-02569B?style=flat-square&logo=flutter"></a>
    <a href="https://github.com/GianSandoval5/MobileLab/releases/tag/v1.1.0"><img alt="MobileLab 1.1" src="https://img.shields.io/badge/MobileLab-1.1-245e57?style=flat-square"></a>
    <a href="LICENSE"><img alt="Licencia MIT" src="https://img.shields.io/badge/license-MIT-245e57?style=flat-square"></a>
  </p>
  <p><a href="#quick-start">Inicio rápido</a> · <a href="#features">Funciones</a> · <a href="#architecture">Arquitectura</a> · <a href="#testing">Pruebas</a> · <a href="CONTRIBUTING.md">Contribuir</a> · <a href="CODE_OF_CONDUCT.md">Conducta</a> · <a href="SECURITY.md">Seguridad</a></p>
  <p><strong>Gian Sandoval · Arquitecto Mobile</strong></p>
</div>

---

Pocket Tasks es una aplicación de ejemplo para organizar pendientes y aprender a separar presentación, reglas de negocio y acceso a datos. A partir de la versión 1.1, utiliza [MobileLab](https://github.com/GianSandoval5/MobileLab) como servicio local: la app realiza peticiones HTTP y MobileLab conserva las tareas en su archivo SQLite.

MobileLab es un sandbox para desarrollo y CI. Para usar esta demo debes mantener su proceso iniciado en tu ordenador. No necesitas una cuenta cloud, una instalación independiente de SQLite ni Docker.

<a id="features"></a>
## Funciones

- Crear, editar, completar y eliminar tareas.
- Buscar pendientes o completadas y ordenar por prioridad.
- Consultar un resumen de progreso y tareas urgentes.
- Conservar documentos en SQLite tras reiniciar el servicio.
- Mostrar errores de conexión y reintentar la carga.
- Probar el cliente HTTP de forma aislada y contra MobileLab real.

<a id="quick-start"></a>
## Inicio rápido

Requisitos: Flutter 3.50 con Dart >=3.13, Android SDK/JDK 17 para Android o macOS/Xcode para iOS, y **MobileLab 1.1.0**.

### 1. Obtener la app

```bash
git clone https://github.com/GianSandoval5/flutter-pocket-tasks.git
cd flutter-pocket-tasks
flutter pub get
```

### 2. Instalar MobileLab

Descarga el binario adecuado desde [MobileLab Releases](https://github.com/GianSandoval5/MobileLab/releases/tag/v1.1.0), verifica su checksum con `SHA256SUMS`, renómbralo como `mobilelab` y agrégalo al `PATH`.

Si prefieres compilarlo, usa Go 1.23 o posterior en una carpeta separada:

```bash
git clone --branch v1.1.0 https://github.com/GianSandoval5/MobileLab.git
cd MobileLab
make build
# Agrega el directorio bin de este clon a tu PATH.
```

### 3. Iniciar el sandbox desde la app

Vuelve a la raíz de `flutter-pocket-tasks`. El repositorio ya incluye `mobilelab.yaml`, la colección y su seed vacío; no hace falta ejecutar `init` sobre ellos.

```bash
mobilelab start
```

Déjalo abierto. El primer inicio crea `mobilelab/data.db` y expone `/api/tasks`. Los siguientes inicios conservan los documentos.

### 4. Ejecutar Flutter desde otra terminal

```bash
cd flutter-pocket-tasks
flutter run
```

La URL por defecto se elige para el emulador Android o el simulador iOS:

| Entorno | URL de MobileLab |
|---|---|
| Android Emulator estándar | `http://10.0.2.2:4566` |
| iOS Simulator en el mismo Mac | `http://127.0.0.1:4566` |
| Pruebas ejecutadas en el ordenador | `http://127.0.0.1:4566` |

Para elegir otra URL, define el origen del sandbox sin `/api/tasks`:

```bash
flutter run --dart-define=MOBILELAB_URL=http://127.0.0.1:4566
```

Para un Android físico conectado por USB, puedes usar `adb reverse tcp:4566 tcp:4566` y esa URL de loopback. Un iPhone físico necesita un host accesible en tu red de desarrollo; `127.0.0.1` en el teléfono se refiere al teléfono. Revisa [la guía de endpoints de MobileLab](https://github.com/GianSandoval5/MobileLab#quick-start).

Android permite HTTP local únicamente en el manifest `debug`. iOS incluye la excepción de red local y una explicación del permiso. Este ejemplo apunta a desarrollo móvil; el acceso desde navegador y sus requisitos de CORS no están certificados por esta integración.

## Cómo se guardan los datos

`mobilelab/data.yaml` declara la colección `tasks` y el campo ID. MobileLab genera las rutas REST y guarda los documentos en `mobilelab/data.db`:

| Operación de la app | Ruta real |
|---|---|
| Leer tareas | `GET /api/tasks` |
| Crear o reemplazar una tarea | `PUT /api/tasks/{id}` |
| Eliminar | `DELETE /api/tasks/{id}` |

Las semillas son sintéticas y la configuración de esta demo no requiere autenticación. No es un servicio público ni una implementación de identidad de producción. La [Data API de MobileLab](https://github.com/GianSandoval5/MobileLab/blob/master/docs/data-api.md) también permite recursos protegidos y otras operaciones.

```bash
mobilelab db status
mobilelab db seed
# Reinicia intencionadamente los documentos de demostración:
mobilelab db reset
```

El archivo de negocio es independiente de `mobilelab/mobilelab.db`, utilizado por MobileLab para su historial. Ambos y el estado del CLI están excluidos de Git.

<a id="architecture"></a>
## Arquitectura

| Capa | Responsabilidad |
|---|---|
| `main.dart` y `core/api_config.dart` | Arranque, selección de URL e inyección |
| `features/tasks/presentation` | Estado de pantalla y operaciones de usuario |
| `features/tasks/domain` | Entidad `Task` y contrato `TaskRepository` |
| `features/tasks/data` | DTO y `MobileLabTaskRepository` por HTTP |
| `mobilelab/` | Contrato SQLite y semillas de desarrollo |
| `test/` | Dominio, estado, cliente HTTP con mocks e interfaz |
| `tool/integration/` | Prueba del adaptador contra la Data API real |

La interfaz depende de `TaskRepository`, lo que permite sustituir el proveedor de datos sin reescribir la presentación. Para conectar un backend de producción, implementa el contrato con su API, autenticación y políticas de acceso reales. El SDK de eventos de MobileLab es opcional y no es necesario para este CRUD.

<a id="testing"></a>
## Pruebas y CI

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test --coverage
python3 scripts/verify_mobilelab.py
flutter build apk --debug
```

`verify_mobilelab.py` utiliza el binario en `PATH` o `MOBILELAB_BIN`, un directorio temporal y un puerto libre. Ejecuta la prueba Dart contra el servicio real y comprueba que un documento sobrevive a detener y volver a iniciar MobileLab. No reinicia tu base de trabajo.

GitHub Actions instala el binario Linux 1.1.0 y comprueba su SHA-256, ejecuta análisis y pruebas, verifica la integración y adjunta el APK debug. La cobertura de los tests unitarios se encuentra en `coverage/lcov.info`; no se afirma una cobertura del 100%.

El APK está en `build/app/outputs/flutter-apk/app-debug.apk`. Si necesitas un host distinto al del emulador Android, compílalo con `--dart-define=MOBILELAB_URL=...`.

## Comunidad

Consulta [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) y [SECURITY.md](SECURITY.md). Hay formularios para errores y mejoras y una plantilla para pull requests. Si te sirve el proyecto, deja una ⭐ para apoyar esta serie de ejemplos abiertos.

## Cambios y alcance

Consulta [CHANGELOG.md](CHANGELOG.md). La versión 1.0 usaba Hive para la primera prueba del publicador; las tareas antiguas no se migran automáticamente al nuevo servicio. `FACTORY_PROVENANCE.json` conserva la evidencia histórica de aquella primera publicación.

Esta demo no incluye sincronización cloud, notificaciones, identidad de producción ni publicación en tiendas. Android se compila en CI; no se afirma una compilación iOS ni una prueba de navegador.

## Licencia

El código original se distribuye bajo [MIT](LICENSE). Las dependencias conservan sus licencias; sus avisos están en [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). MobileLab también conserva su propia licencia MIT.

## Conecta con Gian Sandoval

- [GitHub](https://github.com/GianSandoval5)
- [LinkedIn](https://www.linkedin.com/in/giansandoval/)
- [giansandoval.com](https://giansandoval.com)

**Gian Sandoval — Arquitecto Mobile**
