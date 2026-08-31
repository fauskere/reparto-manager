# 💬 Conversación Oficial: FASE3_PASO3_1_SQLITE_DATA_MODELS
**Fecha:** 2026-08-30  
**Proyecto:** Reparto-Manager V2  
**Entorno:** `C:\Reparto-Manager-DEV`  
**Rama:** `v2-clean-architecture`  
**Hito:** Fase 3 — Capa de Datos Multi-Tenant, Offline-First y Motor de Sincronización (Paso 3.1: Base de Datos Local SQLite y Modelos de Datos)

---

### 👤 USUARIO:
<USER_REQUEST>
¡Bienvenido! Eres el agente oficial a cargo de toda la FASE 3: Capa de Datos Multi-Tenant, Offline-First y Motor de Sincronización en C:\Reparto-Manager-DEV (rama v2-clean-architecture).

Contexto del Proyecto:
- Fase 1 (Design System Atómico y Temas Dinámicos): Completa.
- Fase 2 (Dominio Puro, Entidades, Contratos y 18 Casos de Uso con 41 tests verdes): Completa.

Reglas Globales Innegociables:
- Sandboxing: Antes de cualquier comando flutter usa $env:PUB_CACHE="C:\Reparto-Manager-DEV\.pub-cache".
- Modularización estricta: Archivos < 300 líneas, funciones < 40 líneas.
- Multi-Tenancy Big Tech (Regla 11): Toda tabla exige columna "tenantId TEXT NOT NULL" con índices compuestos para consultas en milisegundos.
- Precisión Bancaria Estricta: Todos los importes monetarios se almacenan como enteros en centavos ("cents: INTEGER NOT NULL"). Prohibido usar double/real para dinero.
- Ventana Caliente: Diseñado para retener localmente 60 días de transacciones en SQLite.

Tu misión para el Paso 3.1: Base de Datos Local SQLite y Modelos de Datos (Data Models):
1. Dependencias en pubspec.yaml (sqflite, sqflite_common_ffi, path, path_provider).
2. Configuración de Base de Datos Local Multiplataforma (lib/data/database/tables_schema.dart, app_database.dart) con 15 tablas.
3. Índices Compuestos de Alto Rendimiento (8 índices compuestos con tenantId).
4. Modelos de Datos y Mapeadores Bidireccionales (lib/data/models/).
5. Batería de Pruebas Unitarias (test/data/).
6. Verificación y Cierre.
</USER_REQUEST>

---

### 🤖 ASISTENTE:
Lectura obligatoria previa completada:
1. `PROJECT_LOG.md`
2. `conversaciones/FASE2_DOMAIN_LAYER.md`

Elaboración y presentación del Plan de Implementación (`implementation_plan.md`):
- Dependencias SQLite con soporte FFI.
- Separación modular de esquema DDL (`tables_schema.dart`) y singleton `AppDatabase`.
- 15 tablas e índices compuestos particionados por `tenantId`.
- Data Models con precisión bancaria en centavos enteros y serialización JSON.
- Suites de pruebas unitarias para SQLite en memoria y mapeadores bidireccionales.

---

### 👤 USUARIO:
<USER_REQUEST>
Plan de implementación APROBADO sin observaciones. Impecable el particionado por (tenantId, id), la precisión en centavos enteros y la separación modular de esquemas DDL.

Como único detalle adicional, incluye también los modelos tipados para "price_history_model.dart" y "sync_queue_model.dart".

Procedé de inmediato con la instalación de dependencias, la creación de la base de datos local, los Data Models, los tests unitarios, la actualización de PROJECT_LOG.md, el commit/push a v2-clean-architecture y el respaldo a KINGSTON.
</USER_REQUEST>

---

### 🤖 ASISTENTE:
Ejecución del Paso 3.1 con 100% de éxito:

1. **Dependencias Instaladas**:
   - `sqflite: ^2.3.3`, `sqflite_common_ffi: ^2.3.3`, `path: ^1.9.0`, `path_provider: ^2.1.3`.
   - `flutter pub get` ejecutado con el PUB_CACHE local (`C:\Reparto-Manager-DEV\.pub-cache`).

2. **Esquema DDL e Índices Compuestos (`lib/data/database/tables_schema.dart`)**:
   - 15 tablas creadas con clave compuesta `(tenantId, id)` y centavos enteros:
     `clients`, `products`, `price_history`, `sales`, `payments`, `truck_loads`, `ledger_entries`, `ledger_snapshots`, `cash_summaries`, `zones`, `client_groups`, `group_invoices`, `promotions`, `app_settings`, `sync_queue`.
   - 8 índices compuestos creados:
     `idx_clients_tenant_zone`, `idx_clients_tenant_name`, `idx_sales_tenant_date`, `idx_sales_tenant_client`, `idx_payments_tenant_date`, `idx_payments_tenant_client`, `idx_ledger_tenant_client_date`, `idx_sync_tenant_status`.

3. **Singleton Multiplataforma (`lib/data/database/app_database.dart`)**:
   - Soporte para FFI en Windows Desktop / tests (`sqfliteFfiInit()`) y móvil nativo.
   - Apertura con PRAGMA foreign_keys y control de versiones.

4. **13 Data Models Tipados Bidireccionales (`lib/data/models/`)**:
   - `client_model.dart`, `product_model.dart`, `price_history_model.dart`, `sale_model.dart`, `payment_model.dart`, `truck_load_model.dart`, `ledger_entry_model.dart`, `cash_summary_model.dart`, `zone_model.dart`, `client_group_model.dart`, `group_invoice_model.dart`, `promotion_model.dart`, `sync_queue_model.dart`.
   - Todos preservan `Money` en `cents: int` y serializan listas/mapas a JSON.

5. **Pruebas Unitarias Exhaustivas (`test/data/`)**:
   - `test/data/database/app_database_test.dart`: 5 tests validando creación de las 15 tablas, 8 índices, aislamiento multi-tenant y claves compuestas `(tenantId, id)`.
   - `test/data/models/models_mapping_test.dart`: 8 tests validando conversión simétrica Entity <-> Model de los 13 modelos.
   - **59/59 tests aprobados (100% verde)**.

6. **Verificación Estática**:
   - `flutter analyze`: **0 issues found** (0 errores, 0 advertencias).
   - Todos los archivos cumplen la regla estricta de < 300 líneas y funciones < 40 líneas.
