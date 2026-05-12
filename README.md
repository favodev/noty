![Noty header](./assets/Noty_Header.png)

**Noty** es una app Android local-first para guardar un historial propio de notificaciones.

Android puede mostrarte una notificación y después hacerla desaparecer: la descartaste sin querer, una app la reemplazó, o simplemente quieres buscar algo que viste hace horas. Noty resuelve eso guardando una copia local en tu teléfono.

## Qué hace

- Captura notificaciones usando la API oficial de Android `NotificationListenerService`.
- Guarda el historial en SQLite local.
- Permite buscar por app, título o contenido.
- Permite filtrar por app y por notificaciones no leídas.
- Permite elegir qué apps monitorear.
- Permite exportar el historial a un archivo JSON.
- Permite importar ese JSON en otro teléfono.
- Permite borrar todo el historial local cuando quieras.

## Privacidad

Noty no usa cuentas, login ni nube.

Tus notificaciones quedan en el dispositivo. Si cambias de teléfono, la portabilidad se hace manualmente: exportas un archivo JSON desde el teléfono viejo y lo importas en el nuevo.

## Cómo funciona

```text
Una app genera una notificación
        ↓
Android la muestra
        ↓
Noty la recibe con NotificationListenerService
        ↓
Noty la guarda en SQLite local
        ↓
Opcionalmente exportas/importas un JSON
```

## Stack

- Flutter para la UI.
- Kotlin para la integración nativa Android.
- SQLite local para persistencia.
- JSON para exportar/importar historial.