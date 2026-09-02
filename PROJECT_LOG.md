## 02/09/2026 - Versión V2 (Fase 3 - Paso 3.3: Motor de Sincronización Bidireccional Offline-First Completo - CIERRE DEFINITIVO DE FASE 3)
- **Qué se hizo**:
  1. **Arquitectura del Motor de Sincronización en la Nube (`lib/data/sync/`)**:
     - `SyncStatus` & `SyncResult`: Estados inmutables (`idle`, `syncing`, `offline`, `error`), métricas tipadas de subida/bajada y notificador reactivo global `syncStatusNotifier` para la UI.
     - `SyncLock`: Candado Mutex de exclusión mutua estricta para evitar condiciones de carrera y gestor de reintentos con backoff exponencial (5s, 15s, 30s) ante fluctuaciones de hotspot.
     - `ICloudGateway` & `FirestoreCloudGateway`: Aislamiento multi-tenant estricto bajo `v2_tenants/{tenantId}/`, consultas con `Source.server` para eludir cachés ciegos, latidos en tiempo real (`sync_heartbeat`), timeouts defensivos de 8s y reconexión forzada de sockets (`disableNetwork` / `enableNetwork`).
     - `SyncPushWorker`: Vaciado atómico de la cola local `sync_queue` hacia Firestore en lotes de hasta 50 documentos por WriteBatch con actualización de marcas temporales de servidor y replicación de tombstones (`isDeleted: true`).
     - `SyncPullWorker`: Sincronización descendente con modo Bootstrap Inicial y modo Delta Incremental (`updatedAtUtc > lastSyncTimestamp`), persistencia de marcas de sincronización en `app_settings` y eliminación física en SQLite ante tombstones.
     - `SyncEngine`: Orquestador singleton con API pública `syncNow({bool forceSocketReset = false, bool forceFullResync = false})`, reconexión automática ante cambios de red (`ConnectivityPlus`), vigía de ciclo de vida (`AppLifecycleListener` al reanudar app/desbloqueo de tablet) y escucha reactiva de latidos.
  2. **Batería de Pruebas Unitarias de Sincronización (`test/data/sync/`)**:
     - `sync_push_worker_test.dart`: 3 tests validando subida en lotes, tombstones de eliminación y purga de cola local.
     - `sync_pull_worker_test.dart`: 4 tests validando bootstrap inicial, modo delta incremental, tombstones y forzado de re-sincronización completa.
     - `sync_engine_orchestration_test.dart`: 4 tests validando exclusión mutua con Mutex, reset de sockets, captura resiliente de errores de red y actualización reactiva de estados.
     - **84/84 tests unitarios aprobados (100% verde)** en todo el proyecto.
  3. **Verificación Estática y Métricas**:
     - `flutter analyze`: **0 issues found** (cero errores, cero advertencias).
     - Modularización estricta respetada al 100% (archivos < 300 líneas y funciones < 40 líneas).
- **Problemas**: Ninguno.
- **Pendientes**: Inicio de la **Fase 4: Capa de Presentación, BLoCs / ViewModels y Vistas Operativas V2**.

## 31/08/2026 - Versión V2 (Fase 3 - Paso 3.2: Implementación Real de los Repositorios Locales SQLite)
- **Qué se hizo**:
  1. **Los 10 Repositorios Locales SQLite (`lib/data/repositories/`)**:
     - `ClientRepositoryImpl`: CRUD de clientes, búsqueda rápida LIKE, reseteo de visitas por zona, actualización de precios especiales y paginación.
     - `ProductRepositoryImpl`: Catálogo activo, filtrado por categorías, búsqueda por código de barras y auditoría automática de aumentos en `price_history`.
     - `SaleRepositoryImpl`: Numeración correlativa de tickets, ventas con desglose contable, arqueo diario consolidado (`CashSummaryEntity` distinguiendo efectivo en mano vs transferencias), rankings de productos y clientes, y anulación.
     - `PaymentRepositoryImpl`: Cobranzas correlativas simples y mixtas, pagos a cuenta y anulación.
     - `TruckRepositoryImpl`: Control de stock a bordo, mermas y aplicación atómica de deltas de existencias tolerando stock negativo para operación en calle.
     - `LedgerRepositoryImpl`: Libro mayor contable bajo Event Sourcing, transacciones atómicas para partida doble (`recordEntries`), cálculo de deuda circulante en O(1) y gestión de snapshots periódicos (Ledger Sharding).
     - `ZoneRepositoryImpl`: Administración de zonas y localidades.
     - `ClientGroupRepositoryImpl`: Agrupación de cadenas y cortes de facturación consolidados (`group_invoices`) con cobranzas asociadas.
     - `PromotionRepositoryImpl`: Gestión de combos y promociones comerciales.
     - `SettingsRepositoryImpl`: Configuración persistente del negocio, tickets y temas visuales en `app_settings`.
  2. **Arquitectura Offline-First y Aislamiento Big Tech (Regla 11)**:
     - `SyncQueueHelper`: Encolado atómico en la tabla `sync_queue` para toda operación de escritura (`INSERT`, `UPDATE`, `DELETE`), dejando los datos listos para el motor de sincronización.
     - Aislamiento multi-tenant estricto con cláusulas obligatorias `WHERE tenantId = ?`.
     - Manejo funcional de errores tipados con `DatabaseFailure extends DomainFailure` sin excepciones no controladas.
  3. **Batería de Pruebas Unitarias de Integración (`test/data/repositories/`)**:
     - `client_and_product_repository_test.dart`: 5 tests de persistencia, búsquedas y auditoría.
     - `sales_and_ledger_repository_test.dart`: 4 tests de ventas, recibos, arqueo de caja y partida doble.
     - `operations_repository_test.dart`: 5 tests de camioneta, zonas, facturación grupal y settings.
     - **73/73 tests aprobados (100% verde)**.
  4. **Verificación Estática y Métricas**:
     - `flutter analyze`: **0 issues found** (cero errores, cero advertencias).
     - Todos los archivos cumplen con el límite modular de < 300 líneas y funciones < 40 líneas.
- **Problemas**: Ninguno.
- **Pendientes**: Paso 3.3 de la Fase 3 (Motor de Sincronización Bidireccional SQLite <-> Firebase con Resolución de Conflictos).

## 30/08/2026 - Versión V2 (Fase 3 - Paso 3.1: Base de Datos Local SQLite y Modelos de Datos)
- **Qué se hizo**:
  1. **Motor SQLite Multiplataforma y Soporte FFI (`lib/data/database/app_database.dart`)**:
     - Singleton `AppDatabase` con inicialización transparente en Windows Desktop (FFI), Android/iOS y pruebas unitarias en memoria (`sqfliteFfiInit()`).
     - Activación de PRAGMA foreign_keys y control de versiones/migraciones.
  2. **Esquema DDL e Índices Compuestos (`lib/data/database/tables_schema.dart`)**:
     - 15 tablas creadas con particionado estricto por `tenantId` y precisión bancaria en centavos enteros (`cents: INTEGER NOT NULL`):
       `clients`, `products`, `price_history`, `sales`, `payments`, `truck_loads`, `ledger_entries`, `ledger_snapshots`, `cash_summaries`, `zones`, `client_groups`, `group_invoices`, `promotions`, `app_settings`, `sync_queue`.
     - 8 índices compuestos de alto rendimiento para consultas en milisegundos:
       `idx_clients_tenant_zone`, `idx_clients_tenant_name`, `idx_sales_tenant_date`, `idx_sales_tenant_client`, `idx_payments_tenant_date`, `idx_payments_tenant_client`, `idx_ledger_tenant_client_date`, `idx_sync_tenant_status`.
  3. **13 Data Models con Mapeo Bidireccional (`lib/data/models/`)**:
     - `client_model.dart`, `product_model.dart`, `price_history_model.dart`, `sale_model.dart`, `payment_model.dart`, `truck_load_model.dart`, `ledger_entry_model.dart`, `cash_summary_model.dart`, `zone_model.dart`, `client_group_model.dart`, `group_invoice_model.dart`, `promotion_model.dart`, `sync_queue_model.dart`.
     - Preservación matemática estricta de centavos de `Money` (cero flotantes binarios) y serialización JSON de colecciones/variantes.
  4. **Batería de Pruebas Unitarias de Persistencia (`test/data/`)**:
     - `test/data/database/app_database_test.dart`: 5 tests validando 15 tablas, 8 índices, aislamiento multi-tenant y claves compuestas `(tenantId, id)`.
     - `test/data/models/models_mapping_test.dart`: 8 tests validando mapeo bidireccional exacto de todos los modelos.
     - **59/59 tests aprobados (100% verde)**.
  5. **Verificación Estática**:
     - `flutter analyze`: **0 issues found** (0 errores, 0 warnings).
     - Todos los archivos respetan el límite modular de < 300 líneas y funciones < 40 líneas.
- **Problemas**: Ninguno.
- **Pendientes**: Paso 3.2 de la Fase 3 (Data Access Objects - DAOs para SQLite).

## 30/08/2026 - Versión V2 (Atomic Design System: Optimización de Nitidez Tipográfica para Monitores de PC)
- **Qué se hizo**:
  1. **Calibración de Escala Tipográfica (`AppTypography` & Componentes Atómicos)**:
     - **Piso Mínimo Estricto**: Ningún texto en toda la app por debajo de 13px (actualizados badges, chips, leyendas, subtítulos y desgloses contables).
     - **Refuerzo de Trazo (ClearType Optimization)**: Eliminados trazos finos (`w300`/`w400`) en textos chicos sobre fondos oscuros o de color; todos los textos menores a 15px utilizan obligatoriamente `FontWeight.w500`, `FontWeight.w600`, `FontWeight.w700` o `FontWeight.w800`.
     - **Espaciado Óptico (`letterSpacing: 0.3`)**: Aplicado a todos los textos pequeños y medianos para prevenir empaste de glifos en monitores de PC.
     - **Tipografía Nativa de Sistema**: `Segoe UI` (fuente nativa de Windows con antialiasing y ClearType perfecto) con fallback a `Inter`, `Roboto` y `sans-serif`.
  2. **Auditoría Exhaustiva de Componentes Visuales**:
     - `StatusChip`, `BalanceBadge`, `ProductCard`, `VariantSelectorChips`, `ClientCard`, `PaymentMethodSelector`, `QuickCashCalculator`, `PaymentSummaryBox`, `MetricSummaryCard`, `RankingItemRow`, `AppHeaderFilterBar` y selector de temas del Showroom calibrados con 13px mínimo y trazos nítidos.
  3. **Pruebas y Verificación**:
     - `flutter test`: 46/46 tests aprobados (100% verde).
     - `flutter analyze lib test`: 0 issues found (cero errores, cero warnings).
     - Despliegue web en canal secundario `dev`: `https://reparto-manager-fb5c2--dev-usamdp3u.web.app`.
- **Problemas**: Ninguno. Tipografía 100% nítida y sólida sin pixelado ni dientes de sierra.
- **Pendientes**: Fase 3 (Capa de Infraestructura SQLite y DAOs).

## 30/08/2026 - Versión V2 (Atomic Design System: 5 Temas Comerciales, Calibración Fina V1 & Roasted Coffee)
- **Qué se hizo**:
  1. **ThemeManager Singleton & 5 Temas Comerciales (`lib/core/design_system/theme_manager.dart`)**:
     - **Reparto Gold** (Identidad Original V1 Exacta): Amarillo María Belén `#FFEB3B` estricto, fondo gris oscuro `#212121`, tarjetas `#2C2C2C`, textos secundarios `#AAAAAA`, texto sobre primario `#000000`.
     - **Midnight Blue**: Azul eléctrico `#2563EB`, pizarra `#1E222B`, tarjetas `#2A2F3D`, detalles `#8E9093`.
     - **Sweet Cream** (Cohesión Visual Boutique): Rosa frambuesa suave `#EC4899`, fondo beige arena `#ECE5D8`, tarjetas `#FFFFFF`, textos café oscuro `#1F1916`. Regla de cohesión: botones de acento/danger usan texto crema cálido `#FAF7F2` (nunca negro ni blanco frío).
     - **Emerald Mint**: Verde esmeralda vivo `#10B981`, fondo grafito `#18181B`, tarjetas `#27272A`.
     - **Roasted Coffee** (Nuevo 5° Tema): Especialidad en cafeterías/panaderías. Primario tono canela/caramelo tostado `#C48B58` con texto crema latte `#FDF8F2`, fondo marrón café tostado profundo `#1F1916`, tarjetas `#2D2420` con bordes suaves `#4A3B32`, textos secundarios `#CBB8A9`.
  2. **Tokens Semánticos y Botones**:
     - Introducido `textOnDanger` en `AppThemePalette` y `AppColors`, consumido por `AppButton` para garantizar contraste y cohesión visual.
     - Barra de búsqueda adaptativa configurada para los 5 temas.
  3. **Showroom Modular y Selector de 5 Temas**:
     - Selector superior con 5 chips táctiles interactivos:
       `[ 🟡 Reparto Gold ] [ 🔵 Midnight Blue ] [ 🌸 Sweet Cream ] [ 🟢 Emerald Mint ] [ ☕ Roasted Coffee ]`.
     - Reactividad instantánea en caliente (0 ms) mediante `ValueKey` y reconstrucción integral.
  4. **Pruebas y Verificación Total**:
     - `flutter test`: 46/46 tests aprobados (100% verde en dominio y 5 temas).
     - `flutter analyze lib test`: 0 issues found (cero errores, cero warnings).
     - Despliegue web en canal secundario `dev`: `https://reparto-manager-fb5c2--dev-usamdp3u.web.app`.
- **Problemas**: Ninguno. 100% verificado y calibrado.
- **Pendientes**: Fase 3 (Capa de Infraestructura SQLite y DAOs).

## 30/08/2026 - Versión V2 (Fase 2 - Paso 2.4: Casos de Uso del Dominio Puro - CIERRE DEFINITIVO DE FASE 2)
- **Qué se hizo**:
  1. **Los 18 Casos de Uso de Negocio Puro (`lib/domain/usecases/`)**:
     - Precios y Promociones:
       * `ResolveProductPriceUseCase`: Jerarquía estricta: `customPrices[variantKey]` > `specialPrice` > `resellerPrice` > `basePrice`.
       * `DuplicateClientPricesUseCase`: Clonación atómica de matrices de precios especiales entre clientes de ruta.
       * `ApplyPromotionUseCase`: Evaluación de combos (`isEligible`) y cálculo de descuento porcentual.
     - Gestión Móvil de Stock en Camioneta:
       * `LoadTruckStockUseCase`: Carga matutina sumando existencias a la capacidad útil.
       * `UnloadTruckStockUseCase`: Descarga de sobrantes al depósito tras el recorrido.
       * `RegisterDamagedStockUseCase`: Registro de roturas/mermas traspasando stock útil a `damagedItems`.
     - Ciclo de Vida de Ventas:
       * `ProcessSaleUseCase`: Validación de invariantes contables, correlativo de ticket, descuento de stock con devoluciones/cambios (`exchanges`), partida doble en Ledger (Débito por venta + Crédito por cobro) y marcado de visita.
       * `UpdateSaleUseCase`: Modificación de venta previa, cálculo de deltas de existencias y asiento contable por diferencia de deuda.
       * `CancelSaleUseCase`: Anulación con restitución íntegra de stock al camión y contra-asiento de crédito en el Ledger.
     - Rutas y Clientes:
       * `ResetZoneRouteUseCase`: Reinicio de visitas matutinas a `notVisited` por zona.
       * `CalculateClientBalanceUseCase`: Cumplimiento estricto de la **Regla 9** (cero forzado manual; suma matemática de último snapshot + asientos delta posteriores).
     - Cobranzas y Ajustes:
       * `RegisterPaymentUseCase`: Cobro simple o mixto con recibo correlativo, crédito contable y visita.
       * `CancelPaymentUseCase`: Anulación de cobro con contra-asiento de débito restituyendo la deuda real.
       * `RecordManualAdjustmentUseCase`: Asiento de saldos iniciales (libreta vieja) o notas de crédito/débito auditadas.
     - Cierres y Facturación Masiva:
       * `GenerateLedgerSnapshotUseCase`: Consolidación periódica de cuenta corriente para consultas en O(1) (**Regla 11**).
       * `CreateGroupInvoiceUseCase`: Facturación agrupada bajo demanda para cadenas comerciales.
       * `PayGroupInvoiceUseCase`: Cobro consolidado de factura de grupo y acreditación contable en Ledger.
       * `GenerateCashSummaryUseCase`: Arqueo diario distinguiendo billetes físicos a rendir vs dinero en cuenta bancaria.
  2. **Batería de Pruebas Unitarias (`test/domain/usecases/`)**:
     - 4 suites modulares (< 300 líneas c/u): `pricing_and_promos_use_cases_test.dart`, `truck_use_cases_test.dart`, `sales_use_cases_test.dart`, `ledger_and_payments_use_cases_test.dart`.
     - **41/41 tests aprobados (100% éxito)** en toda la capa de dominio.
  3. **Verificación Estática y Métricas**:
     - `flutter analyze`: **0 issues found** (cero errores, cero warnings).
     - Todos los archivos del dominio y pruebas cumplen estrictamente la regla de `< 300 líneas` y funciones `< 40 líneas`.
- **Problemas**: Ninguno.
- **Pendientes**: Inicio de la **Fase 3: Capa de Infraestructura y Persistencia Local (SQLite, DAOs y Sincronización)**.

## 30/08/2026 - Versión V2 (Fase 2 - Paso 2.3: Contratos de Repositorio IoC y Arqueo Diario de Caja)
- **Qué se hizo**:
  1. **Entidad de Arqueo de Caja Diario (`lib/domain/entities/cash_summary_entity.dart`)**:
     - `CashSummaryEntity` y `CashSummaryItem`: Desglose inmutable con `Money` que separa el dinero físico a rendir (`totalCash = salesCash + paymentsCash`) del dinero bancario (`totalTransfer = salesTransfer + paymentsTransfer`), recaudación real (`totalRevenue`) y fiado generado hoy (`debtGenerated`), con desglose individual por cliente (`clientBreakdown`).
  2. **Consolidación Forense de Entidades (`lib/domain/entities/`)**:
     - `ClientEntity`: Incorporados campos operativos de V1 (`nickname`, `city`, `isOpenContinuous`, `groupId`), manteniendo `customPrices` indexado por `variantKey` y saldo inmutable.
     - `ZoneEntity`: Entidad inmutable para gestión de zonas y localidades (`cities`).
     - `ClientGroupEntity`: Entidad inmutable para agrupamiento de sucursales y clientes en cadena.
     - `PromotionEntity`: Entidad inmutable para combos y promociones comerciales con evaluación de elegibilidad de carrito (`isEligible`).
     - `SaleItemEntity` y `ExchangeItemEntity`: Modularizados en archivo dedicado (`sale_item_entity.dart`), soportando cambios/devoluciones de mercadería y envases.
     - `SaleEntity`: Actualizado con `exchanges`, `appliedPromos`, `previousBalance` y `remainingBalance`, validando invariantes contables.
     - `PaymentEntity`: Soporte para cobro mixto desglosado (`cashPaid`, `transferPaid`) garantizando `amount == cashPaid + transferPaid` e importe positivo.
     - `ProductEntity`, `ProductVariant` y `TruckLoadEntity`: Verificados y alineados con tolerancia a stock negativo para operación en calle.
  3. **Los 9 Contratos Abstractos de Repositorio IoC (`lib/domain/repositories/`)**:
     - Interfaces abstractas puras con retornos `Future<Result<T, DomainFailure>>`, multi-tenancy estricto (`tenantId`) y paginación (`limit`, `offset`):
       * `IClientRepository`: CRUD, búsqueda, reseteo de visitas por zona y actualización de precios especiales.
       * `IZoneRepository`: Administración de zonas y ciudades.
       * `IClientGroupRepository`: Gestión de cadenas, cortes de facturación (`createGroupInvoice`, `getGroupInvoices`) y cobranzas consolidadas (`payGroupInvoice`).
       * `IProductRepository`: Catálogo, categorías, búsqueda por código de barras e historial de cambios de precio (`getPriceHistory`).
       * `IPromotionRepository`: Gestión de promociones activas.
       * `ISaleRepository`: Consultas, anulaciones, ranking de productos/clientes y arqueo diario consolidado (`getCashSummary`).
       * `IPaymentRepository`: Registro y anulación de cobranzas con numeración correlativa.
       * `ITruckRepository`: Carga de camioneta y aplicación atómica de deltas de existencias.
       * `ILedgerRepository`: Asientos individuales/en lote, total de deuda circulante (`getTotalOutstandingDebt`) y snapshots periódicos.
  4. **Batería de Pruebas Unitarias**:
     - `business_entities_test.dart` y `repository_contracts_test.dart` con Fakes en memoria verificando aislamiento por tenant, paginación, retornos Result y cálculo exacto de `CashSummaryEntity`.
     - **24/24 tests aprobados (100% éxito)**.
  5. **Verificación Estática**:
     - `flutter analyze`: **0 issues found** (0 errores, 0 warnings).
     - Límite de líneas verificado: todos los archivos < 300 líneas y funciones < 40 líneas.
- **Problemas**: Ninguno.
- **Pendientes**: Paso 2.4 de la Fase 2 (Casos de Uso del Dominio: RegistrarVenta, RegistrarCobro, SincronizarCarga, etc.).

## 30/08/2026 - Versión V2 (Fase 2 - Paso 2.2: Entidades Inmutables del Negocio)
- **Qué se hizo**:
  1. **Entidad Cliente (`lib/domain/entities/client_entity.dart`)**:
     - Enums `ClientType` (normal, especial, revendedor) y `VisitStatus` (visited, notVisited, pending).
     - Clase inmutable `ClientEntity` con soporte multi-tenant (`tenantId`), saldo actual (`balance`), límite de crédito (`debtLimit`), indicador de comercio (`isStore`) y mapa unmodifiable `customPrices`.
     - **Directiva 1 cumplida**: `customPrices` indexa por `variantKey` (`productId|variantName`) permitiendo asignaciones de precios específicos por tamaño/variante.
  2. **Entidad Producto y Variantes (`lib/domain/entities/product_entity.dart`)**:
     - `ProductVariant`: Inmutable con `variantName`, clave compuesta `variantKey` (`productId|variantName`), `basePrice`, `costPrice`, `specialPrice`, `resellerPrice`, existencias en depósito y alerta de stock mínimo.
     - `ProductEntity`: Catálogo multi-tenant con categoría, código de barras, imagen y lista unmodifiable de variantes.
  3. **Entidad Venta y Renglón (`lib/domain/entities/sale_entity.dart`)**:
     - Enum `PaymentMethod` (cash, transfer, mixed, onAccount).
     - `SaleItemEntity`: Inmutable con `quantity > 0`, precios, costos, descuento y cálculo exacto de `subtotal`, `totalCost` y `profit`.
     - `SaleEntity`: Correlativo `ticketNumber`, desglose `cashPaid`, `transferPaid`, `debtGenerated`.
     - **Directiva 2 cumplida**: Valida que `totalDiscount <= subtotal` (total nunca negativo).
     - **Directiva 3 cumplida**: Valida que `cashPaid + transferPaid <= total` (el vuelto físico se entrega en mano y solo ingresa a la entidad el monto neto imputado).
     - **Invariante contable estricto**: `cashPaid + transferPaid + debtGenerated == total`.
  4. **Entidad Cobranza/Pago (`lib/domain/entities/payment_entity.dart`)**:
     - `PaymentEntity`: Inmutable con `receiptNumber`, fecha UTC, método de cobro (efectivo o transferencia) y validación de monto positivo (`amount > 0`).
  5. **Entidad Camioneta y Carga Móvil (`lib/domain/entities/truck_load_entity.dart`)**:
     - `TruckLoadEntity`: Control de carga a bordo por `variantKey` y registro de roturas/mermas (`damagedItems`).
     - **Directiva 4 cumplida**: Permite registrar ventas aún con stock negativo (`hasNegativeStock`), garantizando que jamás se bloquee una venta real en la calle por descuadre de carga matutina.
  6. **Batería de Pruebas Unitarias (`test/domain/entities/business_entities_test.dart`)**:
     - 8 nuevos tests cubriendo: invariante de venta, rechazo de sobrepago o sobredescuento, inmutabilidad de colecciones, cálculo de márgenes con Money, precios especiales por `variantKey`, stock negativo tolerado en camioneta y validación de cobros positivos.
     - Total de tests de la suite: **22/22 tests aprobados (100% éxito)**.
  7. **Verificación y Calidad**:
     - `flutter test`: 22/22 tests aprobados.
     - `flutter analyze`: 0 issues found (0 errores, 0 advertencias).
     - Límites de código estrictos cumplidos: todos los archivos < 300 líneas y funciones < 40 líneas.
- **Problemas**: Ninguno.
- **Pendientes**: Paso 2.3 de la Fase 2 (Interfaces de Repositorios Abstractos y Casos de Uso del Dominio).

## 30/08/2026 - Versión V2 (Fase 2 - Paso 2.1: Núcleo Matemático, Primitivas y Event Sourcing Contable)
- **Qué se hizo**:
  1. **Value Object Dinero (`lib/domain/core/money.dart`)**:
     - Implementada clase inmutable `Money` basada en enteros (`int cents`) para eliminar por completo los errores de coma flotante binaria.
     - Directiva bancaria estricta: `Money.fromUnits(num units)` utiliza exclusivamente `(units * 100).round()` para evitar pérdidas de precisión por truncamiento de `toInt()`.
     - Operaciones matemáticas exactas: suma (`+`), resta (`-`), multiplicación escalar (`*`) con redondeo Half-Up y método seguro `divide(num divisor)` que previene crasheos por división por cero retornando `Result.fail(InvalidMoneyAmountFailure)`.
     - Comparadores matemáticos (`==`, `<`, `>`, `<=`, `>=`, `isZero`, `isPositive`, `isNegative`, `abs()`).
     - Formateo comercial argentino: separador de miles con punto (`.`) y centavos en coma (`,`), formateando a entero limpio (ej: `$1.250`) cuando termina en `00` salvo que se invoque con `forceDecimals: true`.
  2. **Manejo Funcional de Resultados y Fallos (`lib/domain/core/result.dart` y `domain_failures.dart`)**:
     - Estructura sellada `Result<S, F>` con variantes `Success<S, F>` y `Failure<S, F>`, métodos funcionales `fold`, `map`, `mapFailure`, eliminando excepciones no controladas en el dominio.
     - Jerarquía inmutable de fallos: `InvalidMoneyAmountFailure`, `NegativeAmountNotAllowedFailure` y `BalanceCalculationFailure`.
  3. **Entidad Contable Inmutable & Ledger Sharding (`lib/domain/entities/ledger_entry_entity.dart`)**:
     - `LedgerEntryEntity`: Asiento contable atómico bajo el patrón Event Sourcing (Stripe / Martin Fowler) con particionado multi-tenant (`tenantId`), `clientId`, `date` UTC, `type` (`LedgerEntryType`), `referenceId`, `amount` y `description`.
     - Auditoría total y balance inmutable: `balanceImpact` suma `+amount` en deudas (`saleDebt`, `adjustmentDebt`) y resta `-amount` en cobranzas y créditos (`paymentCredit`, `adjustmentCredit`).
     - `LedgerSnapshot`: Soporte para cortes y cierres periódicos contables para resolver saldos en O(1) sin reprocesar años de historia.
  4. **Batería de Pruebas Unitarias (`test/domain/core/money_test.dart` y `test/domain/entities/ledger_entry_test.dart`)**:
     - 14 tests unitarios ejecutados con éxito (100% pass):
       a) Precisión decimal exacta demostrada (sumas de múltiples centavos dan exacto).
       b) Débito y crédito restados a la perfección calculando el saldo exacto.
       c) Imposibilidad física de crear montos corruptos (NaN, infinitos o montos negativos en asientos).
       d) Verificación de directiva 4: Venta con entrega en efectivo registrada como 2 asientos independientes (deuda completa y cobranza parcial).
  5. **Verificación y Calidad**:
     - `flutter test`: 14/14 tests aprobados.
     - `flutter analyze`: 0 issues found (0 errores, 0 warnings).
     - Límites de código estrictos cumplidos: todos los archivos < 300 líneas y funciones < 40 líneas.
- **Problemas**: Ninguno.
- **Pendientes**: Paso 2.2 de la Fase 2 (Entidades de Dominio: Cliente, Producto, Venta/Cobro y Catálogo).

## 29/08/2026 - Versión V2 (Fase 1 Completada: Design System & UI Kit Nativo)
- **Qué se hizo**:
  1. **Tokens de Diseño Centralizados (`lib/core/design_system/tokens/`)**:
     - `app_colors.dart`: Paleta oficial con amarillo primario (`#FFFFEB3B`), fondos oscuros (`#212121`, `#2C2C2C`), estados semánticos (éxito, peligro `#EF4444`, advertencia, info) y estados de clientes/visitas.
     - `app_typography.dart`: Jerarquía tipográfica con GoogleFonts Outfit para títulos, cuerpos de texto, números de moneda y captions.
     - `app_spacing.dart`: Escala de espaciados (`xs` a `xxl`), radios de borde (`r8`, `r12`, `r16`, `r24`, `rFull`) y alturas táctiles.
  2. **Componentes Atómicos Reutilizables (`lib/core/design_system/widgets/`)**:
     - `AppButton`: Variantes (Primary, Secondary Outline, Danger, Ghost), tamaños (Small, Medium, Large), estados (Loading con spinner, Disabled), soporte de iconos y opción `fullWidth`.
     - `AppTextField`: Campo de texto oscuro con foco en amarillo brillante, validación y soporte de iconos/prefijos.
     - `BalanceBadge`: Visualizador matemático inmutable de saldo ($0 al día en verde, deudas en rojo `#EF4444`, saldo a favor).
     - `StatusChip`: Chips parametrizados para estados de visita (visitado, no visitado, pendiente), tipos de cliente (normal, especial, revendedor) y medios de pago.
     - `AppCard`: Tarjeta oscura base (`#2C2C2C`) con feedback táctil.
     - `ClientCard`: Tarjeta completa de cliente optimizada para reparto y mostrador (avatar, estado de visita, tipo, badge de saldo y botones directos).
  3. **Showroom Visual Interactivo (`DesignSystemShowroomView`)**:
     - Galería completa en `lib/core/design_system/showroom/design_system_showroom_view.dart` para probar todos los componentes y tokens en vivo.
     - Acceso directo integrado en `lib/modules/shell/app_drawer.dart` ("UI Kit Showroom (V2)").
  4. **Verificación Estricta y Reglas**:
     - `flutter analyze` verificado sin errores ni advertencias (0 issues).
     - Todos los archivos respetan el límite estricto de < 500 líneas y funciones < 50 líneas.
     - Bitácora completa archivada en `conversaciones/FASE1_DESIGN_SYSTEM.md`.

### 🚀 REGLAS MAESTRAS DE ESCALABILIDAD MASIVA & SINGLE SOURCE OF TRUTH (BIG TECH):
1. **Multi-Tenancy Estricto por Usuario (`tenantId`)**:
   - Cada consulta de datos está estrictamente aislada por el usuario autenticado (`tenantId`/`userId`). Queda prohibido descargar o recorrer colecciones globales.
2. **Separación de Datos Calientes (Hot) vs. Fríos (Cold)**:
   - El dispositivo almacena en base de datos local SQLite indexada solo los datos calientes (catálogo activo, clientes de la ruta, ventas/cobranzas de los últimos 30 a 60 días).
   - El historial de años anteriores (10.000 a 100.000+ tickets) vive en la nube y se consulta bajo demanda para no saturar memoria RAM ni datos móviles.
3. **Snapshots Contables de Saldo (Ledger Sharding)**:
   - Los saldos se calculan instantáneamente a partir de balances consolidados periódicos (snapshots mensuales/anuales) + eventos recientes, garantizando consultas en milisegundos sin re-procesar años de historia.
4. **Paginación Obligatoria (Virtual Scrolling)**:
   - Todas las listas de ventas, clientes y comprobantes deben cargar en bloques paginados (ej: de a 20 o 50 registros) para mantener 60 FPS estables y memoria RAM aliviada.
5. **Métricas Pre-agregadas para Reportes**:
   - Los reportes anuales/mensuales leen registros consolidados diarios/mensuales precalculados, nunca suman decenas de miles de tickets en caliente.
6. **Single Source of Truth en UI (Cero Código Residual)**:
   - Toda la interfaz de la aplicación se ensambla exclusivamente a partir de los componentes atómicos del Design System (`lib/core/design_system/widgets/`). Prohibido estilizar botones, encabezados, badges o diálogos sueltos en las vistas para evitar inconsistencias y código residual.
7. **Principio YAGNI y Entrega Incremental Proactiva**:
   - Construir y diseñar únicamente los componentes y modelos requeridos para la fase en curso. No adelantar pantallas ni selectores de fases futuras sobre supuestos no definidos (ej: AFIP o mesas de pizzería se crean en sus fases correspondientes).
   - Proactividad Big Tech: Anticipar la arquitectura de grandes empresas (Shopify, Stripe, Square) en concurrencia, resiliencia y datos sin esperar que el usuario tenga que señalar los vacíos técnicos.

  5. **Purga Absoluta de Deuda Técnica V1 y Clean Boot**:
     - Se eliminaron por completo `lib/modules/`, `lib/models/`, `lib/widgets/`, `lib/scripts/` y archivos sueltos de V1.
     - `lib/main.dart` reescrito desde cero (47 líneas) con inicio directo al `DesignSystemShowroomView`.
     - `lib/` contiene única y exclusivamente `lib/core/design_system/`, `firebase_options.dart` y `main.dart`.
     - Despliegue web en canal secundario `dev`: `https://reparto-manager-fb5c2--dev-usamdp3u.web.app`.
  6. **Consolidación Definitiva del UI Kit V2 (6 Módulos Transversales < 400 líneas)**:
     - **Encabezados & Estructura (`module_header.dart`)**: `ModuleHeader` y `SectionTitle`.
     - **Productos & Catálogo (`product_widgets.dart`)**: `ProductCard`, `ProductListItem` y `VariantSelectorChips`.
     - **Barra Universal de Filtros (`app_header_filter_bar.dart`)**: Fechas compactas con HOY dinámico, períodos, zonas y categorías.
     - **Checkout, Carrito & Vuelto (`checkout_widgets.dart`)**: `CartItemRow`, `PaymentMethodSelector`, `PaymentSummaryBox` y `QuickCashCalculator`.
     - **Diálogos & Modales (`app_dialogs.dart`)**: `AppModalDialog`, `AppConfirmDialog`, `AppReceiptPreviewDialog` (con botón CARGAR EN POS) y `AppSuccessDialog`.
     - **Métricas, Rankings & Estados (`feedback_and_metrics_widgets.dart`)**: `MetricSummaryCard`, `RankingItemRow`, `EmptyStateWidget` y `AppSnackBar`.
     - **Showroom Definitivo (`design_system_showroom_view.dart`)**: 5 pestañas interactivas de prueba táctil completa.
- **Problemas**: Ninguno. 100% verificado con flutter analyze (0 errores, 0 warnings).
- **Pendientes**: Fase 2 (Clean Architecture: Domain Entities, Repositorios SQLite/Firebase y Event Ledger).

## 27/08/2026 - Versión v2.9.80 (Producción Limpia: Fix Sincronización Sincrónica de Ventas y Reconexión Forzada)
- **Qué se hizo**:
  1. **Sincronización Sincrónica de Ventas (`pos_view.dart`)**:
     - Reemplazado `batch.commit().then(...)` asincrónico por `await batch.commit()`. Exige la respuesta del servidor al momento exacto de presionar COBRAR.
  2. **Reconexión Forzada Automática (`enableNetwork`)**:
     - Si la confirmación de red tarda más de 4 segundos por micro-cortes o fluctuaciones de datos móviles en la calle, el sistema ejecuta automáticamente `FirebaseFirestore.instance.enableNetwork()`, forzando la reconexión de sockets con la nube.
  3. **Versión Limpia de Producción (Sin Login)**:
     - Retornada la app a su entrada directa habitual de producción (sin pantalla de login/usuarios).
  4. **Despliegue e Instalación**:
     - WebApp oficial de producción publicada con éxito en `https://reparto-manager-fb5c2.web.app`.
     - APK `v2.9.80` limpia instalada con éxito en la Tablet por ADB inalámbrico (`Success`).
     - Resguardo actualizado en pendrive `H:\reparto-manager`.
- **Problemas**: Resueltos 100%.
- **Pendientes**: Ninguno.

## 28/08/2026 - ESPECIFICACIÓN TÉCNICA OFICIAL Y HOJA DE RUTA — REPARTO MANAGER V2
- **Ubicación del Proyecto**: `C:\Reparto-Manager-V2` (Carpeta Limpia Independiente) / Rama Git `v2-clean-architecture`
- **Metodología de Trabajo**: Estándar Big Tech (Clean Architecture + Atomic Design UI Kit + SRP Estricto)
- **Límite de Líneas**: Funciones < 50 líneas, Archivos < 500 líneas (Hard Cap innegociable de 800 líneas). Separación estricta en `views/`, `actions/`, `repositories/`.

### 📌 REQUERIMIENTOS Y FUNCIONALIDADES OFICIALES V2:

#### A. ESPECIFICACIÓN FUNCIONAL DETALLADA DE REGLAS DE NEGOCIO ACTUALES:

1. **Tipos de Clientes y Jerarquía de Precios (`Client.type`)**:
   - `normal`: Cliente estándar de reparto. Aplica la lista de precios normal, a menos que el cliente tenga un precio personalizado en `customPrices`.
   - `especial`: Cliente institucional / gran volumen. Aplica la lista de precios especiales o `customPrices`.
   - `revendedor`: Revendedor / Distribuidor. Aplica la lista de precios de revendedor y se gestiona en la vista dedicada de revendedores (`resellers_view.dart`).
   - `customPrices`: Mapa de precios individuales `{ productId: precioPersonalizado }`. Si existe una entrada para el producto, el sistema ignora la lista de precios general y aplica este valor fijo.

2. **Estados de Visita y Hoja de Ruta (`Client.lastVisitStatus`)**:
   - `visited` (Verde): Cliente donde se realizó una venta o cobro en el día actual.
   - `not_visited` (Gris): Cliente no visitado.
   - `pending` (Naranja): Cliente marcado en espera o pendiente en la ruta del día.

3. **Formas de Pago y Desglose Financiero (`Sale.paymentMethod`)**:
   - `Efectivo`: `paidAmount = total`, `cashAmount = total`, `transferAmount = 0`.
   - `Transferencia`: `paidAmount = total`, `cashAmount = 0`, `transferAmount = total`.
   - `Mixto`: Desglose manual `cashAmount + transferAmount = paidAmount`.
   - `Pendiente`: `paidAmount = 0`, la totalidad de la venta se suma como deuda al saldo del cliente.

4. **Matemática Exacta de Saldos e Historial de Cuenta**:
   - `saldoAnterior = client.balance`.
   - `deudaGenerada = totalVenta - paidAmount`.
   - `saldoRestante = saldoAnterior + deudaGenerada`.
   - El saldo del cliente **es 100% inmutable** y siempre equivale al resultado exacto de:  
     $$\text{Saldo} = \sum(\text{Ventas/Deudas}) - \sum(\text{Pagos/Cobros})$$

5. **Control de Stock de Camioneta (`TruckLoad`)**:
   - ID de camioneta predeterminado: `truck_principal`.
   - Existencias almacenadas por combinación `productId|variantName`.
   - Al confirmar venta: Descuenta `-cantidad` del stock de la camioneta.
   - Al registrar cambio/devolución: Suma `+cantidad` al stock de la camioneta.

6. **Impresión de Tickets BLE / RawBT**:
   - Encabezado configurable con datos del negocio.
   - Detalle de productos, variantes, cantidades y precios unitarios.
   - Desglose de promociones aplicadas y descuentos.
   - Detalle de pago: Saldo anterior, monto abonado, saldo pendiente actual.
   - Impresión opcional de Duplicado y modo Ticket Limpio.

#### B. NUEVAS FUNCIONALIDADES Y MEJORAS V2 (DISCUTIDAS HOY):
1. **Design System & UI Kit Nativo**:
   - Componentes reutilizables parametrizados (`AppButton`, `AppTextField`, `ClientCard`, `BalanceBadge`, `StatusChip`).
   - Mismo diseño intuitivo, limpio y oscuro de la app actual sin renegados visuales.
2. **4 Perfiles de Negocio Especializados**:
   - 🚚 **Perfil Reparto (Móvil)**: Rutas, Zonas por día, cobranzas en calle, tickets BLE/RawBT, 100% offline-first.
   - 🏪 **Perfil Comercio (Local Fijo)**: Ventas de mostrador, integración con Lector de Código de Barras (USB/Bluetooth/Cámara), stock de depósito.
   - 🍕 **Perfil Gastronomía (Pizzería)**: Comandas de cocina, gestión de mesas, pedidos y deliveries.
   - 🎪 **Perfil Eventos (FoodTruck)**: Venta express rápida y control de stock de evento.
3. **Módulo de Facturación Electrónica ARCA (AFIP)**:
   - Integración nativa WSFEv1 para emisión de Facturas A, B, C y Notas de Crédito.
4. **Módulo de Gastos Operativos & Balance de Ganancia Neta**:
   - Registro de gastos (combustible, mantenimiento, viáticos) y balance `Ventas - Gastos = Ganancia Neta`.
5. **Módulo de Análisis & Gráficos Interactivos**:
   - Gráficos de tendencias de ventas, productos estrella y métricas de cobro.
6. **POS Visual con Fotos de Productos**:
   - Tarjetas de catálogo con fotos de productos y modo lista rápido.
7. **Matemática Inmutable de Saldos (Event Ledger)**:
   - Saldos inmutables por suma matemática de eventos: `Saldo = Suma(Ventas) - Suma(Pagos)`. NUNCA saldos forzados.
8. **Multi-Dispositivo & Multi-Tenant**:
   - App Nativa Windows (`.exe`) con SQLite local offline + App Nativa Android (`.apk`) + Web App (`.pwa`).

---

## 28/08/2026 - Versión v2.9.85 (Purga Física Absoluta de Código e Imports de Usuarios en Rama Master)
- **Qué se hizo**:
  1. **Eliminación Física de Archivos e Imports**:
     - Se eliminó físicamente la carpeta `lib/modules/auth/` (AuthService, LoginView, UserModel) y `users_management_view.dart` de la rama de producción (`master`).
     - Se limpiaron de raíz los imports y escuchadores residuales de `AuthService` en `app_drawer.dart`, `client_groups_actions.dart`, `clients_actions.dart`, `clients_actions_v2.dart`, `inventory_actions.dart`, `promotions_actions.dart`, `reports_actions.dart` y `truck_load_actions.dart`.
  2. **Verificación Estricta**:
     - Cero referencias a `AuthService` o `users` en el código de producción. Compilación limpia al 100%.
  3. **Compilación e Instalación Directa**:
     - APK `v2.9.85` compilado e instalado con desinstalación previa limpia vía ADB USB en la Tablet (`HA25ZAFC` - `Success`).
     - Resguardo actualizado en el pendrive `I:\reparto-manager`.
- **REGLA ABSOLUTA DE AISLAMIENTO DE PROYECTO V2**: El entorno de trabajo de la App V2 es **única y exclusivamente la carpeta `C:\Reparto-Manager-DEV`**. Queda estrictamente prohibido tocar, editar, compilar o modificar cualquier archivo de la carpeta principal de producción `C:\Reparto-Manager` (V1/Tablet).
- **AISLAMIENTO TOTAL DE WEBAPP Y DESPLIEGUE**: La WebApp oficial de producción (`https://reparto-manager-fb5c2.web.app`) está vinculada exclusivamente a V1. Las versiones de desarrollo y pruebas de V2 se despliegan **únicamente en su propio canal y link independiente** (`https://reparto-manager-fb5c2--dev-usamdp3u.web.app/`), imposibilitando cualquier sobreescritura de la web de producción.
- **Regla Estricta de Versionado y Releases GitHub**: Cada avance de código debe subirse a GitHub (`git push`). Cada versión/hito completado debe publicar un Release en GitHub con los 3 binarios compados para descarga inmediata: Web, APK de Android y Executable de Windows (`.exe`), permitiendo retroceder de versión en 1 segundo si surge cualquier fallo.
- **Acceso a Firebase en Múltiples PC**: El archivo `lib/firebase_options.dart` está guardado dentro del proyecto de Git. Al clonar el proyecto en cualquier PC, se descarga automáticamente y se conecta a Firebase sin pedir configuraciones adicionales.
- **GitHub Sincronizado**: Repositorio `https://github.com/fauskere/reparto-manager.git` actualizado con éxito en la rama `master` (producción v2.9.85) y rama `v2-clean-architecture` (desarrollo V2 desde cero con especificación completa).
- **Estado**: Producción en `v2.9.85` limpia e inmune. Laboratorio V2 listo para ser clonado desde cualquier PC.

### 📌 PROCEDIMIENTO OFICIAL ADB USB PARA LA TABLET (COMPROBADO)
- **Ruta ejecutable ADB**: `C:\Users\fausk\AppData\Local\Android\Sdk\platform-tools\adb.exe`
- **ID de Dispositivo USB**: `HA25ZAFC`
- **Comandos de Instalación Directa**:
  1. `& "C:\Users\fausk\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices` (Verificar `HA25ZAFC device`)
  2. `& "C:\Users\fausk\AppData\Local\Android\Sdk\platform-tools\adb.exe" -s HA25ZAFC install -r C:\Reparto-Manager\RepartoManager_Update.apk` (Instalar APK)
  3. `& "C:\Users\fausk\AppData\Local\Android\Sdk\platform-tools\adb.exe" -s HA25ZAFC shell monkey -p com.example.reparto_manager_app -c android.intent.category.LAUNCHER 1` (Iniciar App automáticamente)

## 26/08/2026 - Versión v2.9.79 (Navegación al POS Limpia, Botón Horario Armónico, Menú Duplicar Responsivo y Flecha Zonas Negra)
- **Qué se hizo**:
  1. **Botoncito Switch de Horario (`client_card_item_v2.dart`)**:
     - Redimensionado a un tamaño sutil y armónico (`13px`/`12px`), proporcional a la foto de perfil sin verse exagerado.
  2. **Navegación Automática desde CARGAR EN POS (`client_details_dialogs_v2.dart`)**:
     - Al tocar "CARGAR EN POS", se utiliza `popUntil((route) => route.isFirst)`, cerrando automáticamente el comprobante y la ficha del cliente, enviando al usuario directamente a la pantalla de **Caja / POS** con el cliente y los productos ya cargados.
  3. **Menú Duplicar Lista (`client_price_list_view_v2.dart`)**:
     - Ampliado el ancho a 580px y envuelto el footer en un `Wrap` fluido, evitando cualquier desborde de "APLICAR LISTA" en pantallas tablet/móviles.
  4. **Flechita y Texto "TODAS" (`custom_header_filter_bar.dart`)**:
     - Se aplicó `selectedItemBuilder` para garantizar que la opción "TODAS" y la flechita de selección se muestren siempre en **color negro**.
  5. **Versión**: Incrementada a `v2.9.79`.
  6. **Despliegue e Instalación**:
     - APK `v2.9.79` instalado por ADB inalámbrico en la Tablet (`Success`).
     - WebApp desplegada en Firebase Hosting (`https://reparto-manager-fb5c2.web.app`).
     - Copia de seguridad resguardada en `I:\reparto-manager`.
- **Problemas**: Resueltos 100%.
- **Pendientes**: Ninguno.

## 26/08/2026 - Versión v2.9.78 (Buscador Inventario Limpio, Foto/Switch Cliente Agrandados, Cargar en POS v2 y Convertir en Lista Global)
- **Qué se hizo**:
  1. **Inventario (`inventory_view.dart`)**:
     - Se eliminó el buscador de texto viejo que quedaba duplicado por debajo del `CustomHeaderFilterBar`.
  2. **Clientes, Especiales y Revendedores (`client_card_item_v2.dart`)**:
     - Se agrandó considerablemente la foto de perfil (avatar de cliente de `radius 20/16` a `28/24`).
     - Se agrandó el botón flotante de switch entre horario y tienda (ícono de `14` a `18` con borde amarillo visible).
  3. **Cargar Ticket en POS v2 (`client_details_dialogs_v2.dart`)**:
     - Agregado el botón verde **`CARGAR EN POS`** en el diálogo de detalle de comprobante de la arquitectura V2. Carga los productos exactos de la venta en el carrito y redirige al POS.
  4. **Convertir Lista en Global (`client_price_list_view_v2.dart`)**:
     - Agregado el botón **`CONVERTIR EN LISTA GLOBAL`** dentro de "Duplicar a Otros". Al presionarlo, guarda los precios personalizados actuales directamente en los productos de Firestore como la lista por defecto.
  5. **Versión**: Incrementada a `v2.9.78`.
  6. **Despliegue e Instalación**:
     - APK `v2.9.78` compilado e instalado en la Tablet por ADB (`Success`).
     - Web publicada en Firebase Hosting (`https://reparto-manager-fb5c2.web.app`).
     - Resguardo completado en el pendrive `I:\reparto-manager`.
- **Problemas**: Todos resueltos y comprobados.
- **Pendientes**: Ninguno.

## 26/08/2026 - Versión v2.9.77 (Perfeccionamientos de Layout, Autocompletado de Espacios y Filtro "Otros")
- **Qué se hizo**:
  1. **Caja / POS (`pos_view.dart`)**:
     - El botón/switch de cambiar entre cuadrícula y lista fue movido a la **AppBar arriba a la derecha** en la misma línea del título "Caja / POS".
     - El texto del botón `+ Cliente` cambió a **"Cliente"** (para no duplicar el signo + del ícono).
  2. **Autocompletado de Espacios en `CustomHeaderFilterBar`**:
     - El módulo de **Navegador de Fechas** ahora está envuelto en un `Expanded`, estirándose automáticamente para rellenar de punta a punta todo el ancho restante de la pantalla/contenedor sin dejar huecos vacíos.
  3. **Reportes (`reports_view.dart`)**:
     - Ícono de impresora en el segundo componente cambiado a **amarillo brillante (`AppTheme.primaryYellow`)**.
     - Tabs `[Tickets]` y `[Entradas Dinero]`: El activo tiene fondo amarillo y texto negro; el inactivo tiene **estilo hueco** (fondo transparente, borde amarillo y texto amarillo).
  4. **Clientes Especiales (`special_clients_view_v2.dart`)**:
     - Quitados los botones "Agrupar Clientes" y "Precios Especiales Globales" de la AppBar superior.
     - Ubicados abajo en la barra inferior con **estilo hueco** (borde amarillo transparente) a la derecha de "Agregar Especial".
  5. **Catálogo de Precios (`price_catalog_view.dart`)**:
     - Agregada explícitamente la categoría **`Sin Categoría / Otros`** en los filtros por categoría para permitir visualizar u ocultar los productos sin categoría asignada.
  6. **Versión**: Actualizada a `v2.9.77`.
  7. **Despliegue e Instalación**:
     - APK `v2.9.77` compilado e instalado con éxito en la Tablet vía ADB inalámbrico (`Success`).
     - WebApp publicada con éxito en Firebase Hosting (`https://reparto-manager-fb5c2.web.app`).
     - Copia de resguardo del código fuente realizada hacia el pendrive `I:\reparto-manager`.
- **Problemas**: Resueltos 100%.
- **Pendientes**: Probar la v2.9.77 en la tablet.

## 26/08/2026 - Versión v2.9.76 (CustomHeaderFilterBar Unificado en TODAS las Vistas y Duplicar como Global)
- **Qué se hizo**:
  1. **Integración Completa de CustomHeaderFilterBar (1 Renglón por Debajo)**:
     - **Caja / POS**: `CustomHeaderFilterBar` ubicado un renglón debajo del título "Caja / POS". Contiene Categorías (blister, etc.), Zonas (con "TODAS"), Navegador de Fechas hiper-compacto (flechas + HOY pegados) y el botón `+ Cliente` / Nombre de Cliente seleccionado integrado a la derecha dentro de la barra.
     - **Reportes**: `CustomHeaderFilterBar` principal debajo del título "Reportes" con filtro de Día/Semana/Mes, Navegador de Fechas e impresora/zona.
     - **Reportes (Segundo Componente - Historial de Tickets)**: `CustomHeaderFilterBar` secundario integrado debajo del título "Historial de Tickets", conteniendo el Buscador (cliente/ticket), botón de Impresora y los tabs de selección `[Tickets]` / `[Entradas Dinero]`.
     - **Clientes**: `CustomHeaderFilterBar` ubicado en un renglón dedicado debajo del título "Clientes" tanto en vista vertical como horizontal.
     - **Clientes Especiales**: `CustomHeaderFilterBar` ubicado un renglón por debajo con buscador, Zonas y **ordenamiento A-Z / Z-A / Saldo**.
     - **Revendedores**: `CustomHeaderFilterBar` ubicado un renglón por debajo con buscador, Zonas y **ordenamiento A-Z / Z-A / Saldo**. Botón *"Precios Revendedor"* configurado con **estilo hueco** (borde amarillo transparente) idéntico a Inventario.
     - **Inventario**: `CustomHeaderFilterBar` ubicado un renglón por debajo del título "Inventario", unificando el Buscador y el Ordenamiento A-Z / Precio.
     - **Catálogo de Precios**: `CustomHeaderFilterBar` ubicado un renglón por debajo, incluyendo el buscador de productos y el filtro de Categorías por checkboxes. Tarjetas de catálogo e ítems **agrandados (16px/18px y padding 12px)** para máxima visibilidad.
  2. **Duplicar / Cargar Lista Mayorista como Global**:
     - Agregada la opción **"⭐ Lista Global Base (Precios por Defecto)"** en el diálogo de Duplicar/Cargar lista de precios (`client_price_list_view_v2.dart`), permitiendo blanquear precios personalizados para volver a aplicar la Lista Global.
  3. **Versión**: Actualizada a `v2.9.76`.
  4. **Despliegue e Instalación**:
     - APK `v2.9.76` compilado e instalado con éxito en la Tablet vía ADB inalámbrico (`Success`).
     - WebApp publicada con éxito en Firebase Hosting (`https://reparto-manager-fb5c2.web.app`).
     - Copia de resguardo del código fuente realizada hacia el pendrive `I:\reparto-manager`.
- **Problemas**: Resueltos 100%.
- **Pendientes**: Probar la v2.9.76 en la tablet.

## 26/08/2026 - Versión v2.9.75 (Cargar Pedido en POS, CustomHeaderFilterBar, Top 10 y Filtros de Zona)
- **Qué se hizo**:
  1. **Cargar Pedido en POS desde Ficha del Cliente**:
     - Botón verde CARGAR EN POS dentro de cada comprobante previo para repetir/modificar pedidos.
  2. **Módulo Universal CustomHeaderFilterBar**:
     - Componente reutilizable en lib/widgets/custom_header_filter_bar.dart con botón HOY dinámico, selector de período y zonas con TODAS.
  3. **Reorganizaciones de UI en POS y Reportes**:
     - POS: Excluidos revendedores del selector de cliente (orden A-Z). Layout vertical y horizontal ajustado.
     - Reportes: Ranking ampliado a Top 10 Productos y Top 10 Clientes.
  4. **Revendedores y Catálogo de Precios**:
     - Botón Precios Revendedor movido al módulo inferior. Buscador en negro para máxima legibilidad.
     - Catálogo de Precios: Tipografía y tarjetas ampliadas a 16px para mejor lectura.
  5. **Versión**: Actualizada a v2.9.75.
  6. **Despliegue e Instalación**:
     - APK v2.9.75 instalado con éxito en la Tablet via ADB inalámbrico (Success).
     - WebApp publicada con éxito en Firebase Hosting (https://reparto-manager-fb5c2.web.app).
     - Copia de resguardo del código fuente realizada hacia el pendrive I:\reparto-manager.
- **Problemas**: Resueltos 100%.
- **Pendientes**: Probar la v2.9.75 en la tablet.

## 26/08/2026 - Versión v2.9.74 (Historial de Precios, Filtro Sin Categoría y Actualización Individual)
- **Qué se hizo**:
  1. **Actualización Individual de Precios con Historial**:
     - Agregado el botón Actualizar Precio en la barra inferior de Inventario.
     - Permite buscar un producto/variante e ingresar su nuevo precio guardando el cambio en Firestore e insertando el historial en price_history.
  2. **Filtro Sin Categoría en Catálogo**:
     - Añadida explícitamente la categoría Sin Categoría en los filtros por categoría.
  3. **Modularización y Limpieza**:
     - Reestructurado inventory_view.dart en exactamente 916 líneas de código limpio.
  4. **Versión**: Actualizada a v2.9.74.
  5. **Despliegue e Instalación**:
     - APK v2.9.74 compilado e instalado con exito en la Tablet via ADB inalámbrico (Success).
     - WebApp publicada con exito en Firebase Hosting (https://reparto-manager-fb5c2.web.app).
     - Copia de resguardo del código fuente realizada hacia el pendrive H:\reparto-manager.
- **Problemas**: Resueltos 100%.
- **Pendientes**: Probar la v2.9.74 en producción.

## 25/08/2026 - Versión v2.9.73 (Filtros Compactos, Selector de Zonas, Doble Ranking y Categorías con Checkboxes)
- **Qué se hizo**:
  1. **Rediseño Compacto del Filtro de Fechas (Resumen de Caja)**:
     - Unificada la barra superior en una sola línea elegante.
     - Une el selector de Período (Día/Semana/Mes/Año/Todo), el navegador de fecha con flechas integradas y el selector de Zonas.
  2. **Selector Unificado de ZONAS (con opción TODAS por defecto)**:
     - Integrada la opción `TODAS` en el selector de zona de Resumen de Caja y Reportes.
  3. **Doble Ranking en Reportes (Top 5 Productos + Top 5 Mejores Clientes)**:
     - Rediseñado el bloque de ranking en `ReportsView` a **2 columnas paralelas**:
       - Columna izquierda: **Top 5 Productos más vendidos** (con unidades vendidas).
       - Columna derecha: **Top 5 Mejores Clientes** (quienes compraron más por monto total).
  4. **Catálogo de Precios Avanzado (Filtro por Categorías con Checkboxes)**:
     - Agregado el botón **"Categorías"** en `PriceCatalogView`.
     - Abre un diálogo con **checkboxes tildables/destildables** por cada categoría existente en el inventario.
     - Permite filtrar la grilla del catálogo de precios dinámicamente seleccionando una o varias categorías.
  5. **Versión**: Actualizada a `v2.9.73`.
  6. **Despliegue e Instalación**:
     - APK `v2.9.73` transmitido e instalado con éxito en la Tablet por ADB inalámbrico (`Success`).
     - WebApp publicada con éxito en Firebase Hosting (`https://reparto-manager-fb5c2.web.app`).
     - Copia de seguridad del código fuente actualizada en el pendrive `H:\reparto-manager`.

- **Problemas**: Resueltos 100%.
- **Pendientes**: Probar la versión v2.9.73 en la Tablet.
