# 💬 Conversación Oficial: FASE3_PASO3_3_MOTOR_SINCRONIZACION_CLOUD
**Fecha:** 2026-09-02  
**Proyecto:** Reparto-Manager V2  
**Entorno:** `C:\Reparto-Manager-DEV`  
**Rama:** `v2-clean-architecture`  
**Hito:** Fase 3 — Capa de Datos Multi-Tenant, Offline-First y Motor de Sincronización (Paso 3.3: Motor de Sincronización Bidireccional Offline-First Completo en `lib/data/sync/` — CIERRE DEFINITIVO DE FASE 3)

---

### 👤 USUARIO:
<USER_REQUEST>
Llegamos al paso final y más crucial de la FASE 3: Capa de Datos Multi-Tenant en C:\Reparto-Manager-DEV (rama v2-clean-architecture).

Tu misión es implementar el Paso 3.3: Motor de Sincronización Bidireccional Offline-First Completo (Cloud Sync Engine) en lib/data/sync/.
Este motor comunica la base de datos local SQLite con Firestore (bajo "v2_tenants/{tenantId}/"), resolviendo de raíz el problema de los sockets dormidos en Android, la falta de respuesta en hotspot y la sincronización multi-dispositivo.

Reglas Globales Innegociables:
- Sandboxing: Antes de cualquier comando flutter usa $env:PUB_CACHE="C:\Reparto-Manager-DEV\.pub-cache".
- Modularización estricta: Archivos < 300 líneas, funciones < 40 líneas.
- Aislamiento Firestore: Toda lectura y escritura en la nube debe apuntar estrictamente a "v2_tenants/{tenantId}/{collectionName}".
- Resiliencia de Red: Manejo de timeouts (máximo 8 segundos por lote) y captura de SocketException / FirebaseException sin arrojar excepciones no controladas.

1. DEPENDENCIAS EN PUBSPEC.YAML
- connectivity_plus: ^6.0.5

2. ARQUITECTURA DEL MOTOR DE SINCRONIZACIÓN (lib/data/sync/)
1. Estado y Resultado (sync_status.dart)
2. Candado Mutex y Resiliencia (sync_lock.dart)
3. Obrero de Subida / Push (sync_push_worker.dart)
4. Obrero de Bajada / Pull (sync_pull_worker.dart)
5. Orquestador, Ciclo de Vida y Reconexión Forzada (sync_engine.dart)

3. BATERÍA DE PRUEBAS UNITARIAS (test/data/sync/)
4. CIERRE Y VERIFICACIÓN DEFINITIVA DE FASE 3
</USER_REQUEST>

---

### 🤖 ASISTENTE:
Presentación y aprobación de Plan de Implementación (`implementation_plan.md`):
- Incorporación de `ICloudGateway` para desacoplamiento testeable.
- Mutex anti-concurrencia, backoff exponencial, `Source.server` estricto y replicación de tombstones.

---

### 👤 USUARIO:
Plan aprobado sin observaciones.

---

### 🤖 ASISTENTE:
Ejecución del Paso 3.3 y cierre definitivo de la Fase 3:

1. **Dependencias**:
   - `connectivity_plus: ^6.0.5` instalada con `flutter pub get` bajo `$env:PUB_CACHE="C:\Reparto-Manager-DEV\.pub-cache"`.

2. **Arquitectura del Motor de Sincronización (`lib/data/sync/`)**:
   - `sync_status.dart`: `SyncState` (`idle`, `syncing`, `offline`, `error`), `SyncResult` y `syncStatusNotifier` reactivo para la UI.
   - `sync_lock.dart`: Mutex de exclusión mutua para evitar condiciones de carrera y reintentos con backoff exponencial.
   - `cloud_gateway.dart`: Contrato `ICloudGateway` e implementación `FirestoreCloudGateway` con particionado `v2_tenants/{tenantId}/`, `Source.server`, timeouts de 8s y reconexión forzada de sockets (`disableNetwork`/`enableNetwork`).
   - `sync_push_worker.dart`: Subida atómica por lotes de 50 de `sync_queue` a Firestore con tombstones (`isDeleted: true`) y purga local.
   - `sync_pull_worker.dart`: Descargas bootstrap e incremental por `updatedAtUtc`, eliminación física por tombstones y marcas en `app_settings`.
   - `sync_engine.dart`: Singleton orquestador, reconexión por conectividad (`ConnectivityPlus`), vigía de ciclo de vida (`AppLifecycleListener`) y escucha de latidos en tiempo real.

3. **Pruebas Unitarias (`test/data/sync/`)**:
   - `sync_push_worker_test.dart`: 3 tests verdes.
   - `sync_pull_worker_test.dart`: 4 tests verdes.
   - `sync_engine_orchestration_test.dart`: 4 tests verdes.
   - **Total de pruebas del proyecto: 84/84 tests aprobados (100% verde)**.

4. **Verificación Estática**:
   - `flutter analyze`: **0 issues found** (0 errores, 0 warnings).
   - Límite estricto de líneas (< 300 líneas por archivo y < 40 líneas por función) cumplido.
