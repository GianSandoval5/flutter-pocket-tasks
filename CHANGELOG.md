# Cambios

## 1.1.0

- MobileLab Data API reemplaza Hive como fuente de datos principal.
- CRUD real por HTTP y persistencia SQLite en `mobilelab/data.db`.
- URL configurable por plataforma y mensajes de conexión al sandbox.
- Pruebas del cliente HTTP con mocks y verificación real de CRUD y persistencia al reiniciar MobileLab.
- README con portada, badges y navegación; guías de contribución, conducta y seguridad; plantillas de issues y PR.

Las tareas de la versión 1.0 guardadas en Hive no se transfieren automáticamente a MobileLab. El cambio no elimina deliberadamente la caja anterior del dispositivo; utiliza datos de demostración o exporta los datos de una versión anterior antes de cambiar de almacenamiento.

## 1.0.0

- Primera demostración de infraestructura, con tareas locales en Hive, pruebas y compilación Android.
- La evidencia original se conserva en `FACTORY_PROVENANCE.json`; describe aquella publicación inicial, no el estado del código 1.1.
