# 💬 Conversación Oficial: FASE2_DOMAIN_LAYER
**Fecha:** 2026-08-30  
**Proyecto:** Reparto-Manager V2  
**Entorno:** `C:\Reparto-Manager-DEV`  
**Rama:** `v2-clean-architecture`  
**Hito:** Fase 2 — Capa de Dominio Puro y Reglas de Negocio (Paso 2.1: Núcleo Matemático y Financiero Inmutable)

---

### 👤 USUARIO:
<USER_REQUEST>
Hola. Iniciamos la FASE 2: Capa de Dominio Puro y Reglas de Negocio en Reparto-Manager V2, trabajando en C:\Reparto-Manager-DEV (rama v2-clean-architecture).

Reglas Fundamentales del Proyecto:
- Aislamiento total: Solo trabajar en C:\Reparto-Manager-DEV con $env:PUB_CACHE="C:\Reparto-Manager-DEV\.pub-cache".
- Dominio Puro: Esta capa NO depende de Flutter (salvo anotaciones básicas si hicieran falta), NI de Firebase, NI de UI. Es Dart puro, matemática estricta y modelos inmutables.
- Principio YAGNI Estricto: Vamos a construir paso a paso. En este primer paso construiremos ÚNICA Y EXCLUSIVAMENTE el Núcleo Matemático y Financiero (Paso 2.1). No adelantes pantallas, ni repositorios de base de datos todavía.
- Límite estricto de líneas: Archivos < 300 líneas, funciones < 40 líneas.

Tu misión para este Paso 2.1:
Construir en lib/domain/core/ las primitivas matemáticas y la entidad contable inmutable:

1. Value Object Dinero (lib/domain/core/money.dart):
   - Clase inmutable "Money" para representar montos financieros exactos sin errores de coma flotante binaria (almacena el valor en centavos enteros: int cents).
   - Operaciones matemáticas exactas: suma (+), resta (-), multiplicación por cantidad (*) y división con redondeo bancario estricto (RoundHalfUp).
   - Formateo a String con símbolo de moneda "$", separadores de miles y centavos opcionales.
   - Comparadores (==, <, >, <=, >=, isZero, isPositive, isNegative).

2. Manejo Tipado de Resultados y Fallos (lib/domain/core/result.dart y lib/domain/core/domain_failures.dart):
   - Patrón Result<T, DomainFailure> (o Either) para evitar que el código lance excepciones no controladas.
   - Definición de fallos claros: InvalidMoneyAmountFailure, NegativeAmountNotAllowedFailure, BalanceCalculationFailure.

3. Entidad Contable Inmutable (lib/domain/entities/ledger_entry_entity.dart):
   - Modelo de Asiento Contable (Ledger Entry) bajo el patrón Event Sourcing de Stripe / Martin Fowler:
     * id: String (identificador único del movimiento)
     * tenantId: String (particionado estricto de usuario)
     * clientId: String (cliente al que se imputa)
     * date: DateTime (marca temporal UTC)
     * type: Enum LedgerEntryType (saleDebt: deuda por venta, paymentCredit: pago/cobranza a favor, adjustmentCredit: nota de crédito/ajuste a favor, adjustmentDebt: ajuste deudor)
     * referenceId: String (id del comprobante o ticket asociado)
     * amount: Money (monto inmutable)
     * description: String (detalle del movimiento)
   - Snapshot Contable (LedgerSnapshot): Para cierres periódicos sin re-procesar años de historia.

4. Batería de Tests Unitarios Obligatorios (test/domain/core/money_test.dart y test/domain/entities/ledger_entry_test.dart):
   - Escribe y ejecuta tests unitarios con "flutter test" que demuestren matemáticamente que:
     a) No existen errores de precisión decimal (ej: sumar múltiples centavos da exacto).
     b) Un débito y un crédito se restan a la perfección dando el balance esperado.
     c) Es físicamente imposible crear montos corruptos.

5. Verificación y Cierre del Paso 2.1:
   - Asegúrate de que "flutter analyze" y "flutter test" pasen con 100% de éxito (0 errores).
   - Actualiza PROJECT_LOG.md registrando el hito Paso 2.1.
   - Exporta el chat a conversaciones/FASE2_DOMAIN_LAYER.md.
   - Comitea y pushea a la rama v2-clean-architecture.
   - Realiza la copia de respaldo hacia el pendrive detectado con etiqueta KINGSTON.
   - Reporta los resultados para pasar al siguiente paso (Paso 2.2).
</USER_REQUEST>

---

### 🤖 ASISTENTE:
Lectura obligatoria previa realizada:
1. `PROJECT_LOG.md`
2. `conversaciones/FASE1_DESIGN_SYSTEM.md`

Propuesta del Plan de Implementación (`implementation_plan.md`) para el Paso 2.1:
- Value Object `Money` en centavos enteros con precisión bancaria.
- Estructura `Result<S, F>` sellada y jerarquía `DomainFailure`.
- Entidad `LedgerEntryEntity` con `LedgerEntryType` y `LedgerSnapshot`.
- Pruebas unitarias completas.

---

### 👤 USUARIO:
<USER_REQUEST>
El plan está APROBADO con estas 3 directivas obligatorias de ingeniería bancaria:

1. En Money.fromUnits(num units), usa estrictamente (units * 100).round() para evitar la trampa de coma flotante de toInt().
2. En la división de Money, si el divisor es 0, no permitas que la app crashee; maneja el fallo con InvalidMoneyAmountFailure.
3. En el formateo de Money, si cents termina en 00, formatea como entero limpio (ej: "$1.250") a menos que se especifique forceDecimals: true, para adaptarlo a la realidad comercial de Argentina.
4. Recuerda que ante una venta con entrega en efectivo (pago parcial), se registran dos asientos independientes en el Ledger (la venta completa y el pago) para garantizar auditoría total.

Procedé con la ejecución del Paso 2.1 y la batería de tests unitarios.
</USER_REQUEST>

---

### 🤖 ASISTENTE:
Ejecución del Paso 2.1 cumpliendo estrictamente con todas las directivas:

1. **Jerarquía de Fallos de Dominio (`lib/domain/core/domain_failures.dart`)**:
   - `DomainFailure` (abstracta e inmutable con `==` y `hashCode`).
   - Subclases: `InvalidMoneyAmountFailure`, `NegativeAmountNotAllowedFailure`, `BalanceCalculationFailure`.

2. **Manejo Funcional de Resultados (`lib/domain/core/result.dart`)**:
   - Clase sellada `Result<S, F>` con variantes `Success<S, F>` y `Failure<S, F>`.
   - Métodos funcionales: `fold`, `map`, `mapFailure`, `isSuccess`, `isFailure`, `valueOrNull`, `failureOrNull`.

3. **Value Object Money (`lib/domain/core/money.dart`)**:
   - Almacenamiento en `int cents`.
   - Constructor `Money.fromUnits(num units)` con `(units * 100).round()`.
   - `divide(num divisor)` seguro retornando `Result<Money, DomainFailure>` (manejo de división por cero con `InvalidMoneyAmountFailure`).
   - Operaciones `+`, `-`, `*` (Half-Up).
   - Formateo comercial argentino con puntos para miles y comas para decimales, simplificando enteros a `$1.250` salvo `forceDecimals: true`.

4. **Entidad Contable Inmutable (`lib/domain/entities/ledger_entry_entity.dart`)**:
   - `LedgerEntryType`: `saleDebt`, `paymentCredit`, `adjustmentCredit`, `adjustmentDebt`.
   - `LedgerEntryEntity`: Event Sourcing inmutable con validación de montos positivos y firma contable en `balanceImpact`.
   - `LedgerSnapshot`: Cierres contables periódicos para calcular saldos en tiempo constante.

5. **Batería de Pruebas Unitarias**:
   - `test/domain/core/money_test.dart`: 9 tests exhaustivos de precisión, coma flotante, formateo argentino y protección contra montos corruptos.
   - `test/domain/entities/ledger_entry_test.dart`: 5 tests contables de conciliación débito/crédito, pagos parciales en 2 asientos y consolidación con snapshots.
   - Resultado: 14/14 tests aprobados (100% éxito).

6. **Verificación Estática**:
   - `flutter analyze`: 0 issues found (0 errores, 0 warnings).
   - Límites de líneas: todos los archivos < 300 líneas y funciones < 40 líneas.

---

### 👤 USUARIO:
<USER_REQUEST>
Continuamos con la FASE 2: Capa de Dominio Puro en C:\Reparto-Manager-DEV (rama v2-clean-architecture).

Ahora ejecutaremos el Paso 2.2: Entidades Inmutables del Negocio.
Todas las entidades deben ser Dart puro (sin dependencias de UI ni Firebase), inmutables (con copyWith, == y hashCode), utilizando nuestro Value Object "Money" para todos los importes y asegurando el aislamiento multi-tenant con "tenantId".

Límites estrictos: Archivos < 300 líneas, funciones < 40 líneas.

Tu misión para este Paso 2.2 en lib/domain/entities/:
1. Entidad Cliente (lib/domain/entities/client_entity.dart)
2. Entidad Producto y Variantes (lib/domain/entities/product_entity.dart)
3. Entidad Venta y Renglón de Venta (lib/domain/entities/sale_entity.dart)
4. Entidad Cobranza/Pago (lib/domain/entities/payment_entity.dart)
5. Entidad Camioneta y Stock Móvil (lib/domain/entities/truck_load_entity.dart)
6. Batería de Tests Unitarios (test/domain/entities/business_entities_test.dart)
7. Verificación y Cierre.
</USER_REQUEST>

---

### 👤 USUARIO:
<USER_REQUEST>
Atención: Revisé el plan en profundidad y tenés 4 correcciones arquitectónicas obligatorias antes de programar:

1. En ClientEntity, customPrices DEBE ser Map<String, Money> donde la clave sea el "variantKey" (formato "productId|variantName"), NO solo el productId. Los precios especiales se asignan por variante/tamaño, no por producto genérico.
2. En SaleEntity, valida que totalDiscount jamás sea mayor a subtotal. El total de una venta nunca puede ser negativo.
3. En SaleEntity, valida que (cashPaid + transferPaid) jamás supere el total. (El vuelto físico se entrega en mano; a la entidad solo ingresa el monto neto aplicado a la venta).
4. En TruckLoadEntity, el stock de la camioneta debe permitir registrar ventas aunque el inventario quede en negativo (con advertencia), para NUNCA bloquear una venta real en la calle por descuadre de carga matutina.

Ajustá el plan con estos 4 puntos y procedé con el Paso 2.2.
</USER_REQUEST>

---

### 🤖 ASISTENTE:
Ejecución completa del Paso 2.2 incorporando las 4 correcciones arquitectónicas:

1. **ClientEntity (`lib/domain/entities/client_entity.dart`)**:
   - `ClientType` (`normal`, `especial`, `revendedor`) y `VisitStatus` (`visited`, `notVisited`, `pending`).
   - `customPrices`: `Map<String, Money>` inmutable usando `variantKey` (`productId|variantName`) como clave.
   - `balance`, `debtLimit`, `isStore`, `isActive`.
   - Método `getPriceForVariant(variantKey, fallbackBasePrice)`.

2. **ProductEntity y ProductVariant (`lib/domain/entities/product_entity.dart`)**:
   - `ProductVariant`: Inmutable con `variantName`, `variantKey` (`productId|variantName`), `basePrice`, `costPrice`, precios diferenciales, existencias y margen unitario.
   - `ProductEntity`: Multi-tenant, catálogo por categorías, barcode, imagen y lista inmutable de variantes.

3. **SaleEntity y SaleItemEntity (`lib/domain/entities/sale_entity.dart`)**:
   - `PaymentMethod`: `cash`, `transfer`, `mixed`, `onAccount`.
   - `SaleItemEntity`: Inmutable con cálculo exacto de `subtotal`, `totalCost` y `profit`.
   - `SaleEntity`:
     * Valida que `totalDiscount <= subtotal` (Directiva 2).
     * Valida que `cashPaid + transferPaid <= total` (Directiva 3).
     * Invariante matemático estricto: `cashPaid + transferPaid + debtGenerated == total`.

4. **PaymentEntity (`lib/domain/entities/payment_entity.dart`)**:
   - Cobranzas inmutables en efectivo o transferencia con comprobante y validación de monto positivo (`amount > 0`).

5. **TruckLoadEntity (`lib/domain/entities/truck_load_entity.dart`)**:
   - Control de existencias a bordo por `variantKey` y mermas en `damagedItems`.
   - Tolerancia a saldos de stock negativos (`hasNegativeStock`, `negativeStockVariantKeys`) para permitir operar en la calle ante descuadres de carga matutina (Directiva 4).

6. **Batería de Pruebas Unitarias (`test/domain/entities/business_entities_test.dart`)**:
   - 8 tests exhaustivos demostrando invariantes, inmutabilidad, cálculo de márgenes, precios especiales por variante, stock negativo tolerado y validación de cobros.
   - Suite total: **22/22 tests aprobados (100% éxito)**.

7. **Verificación Estática y Métricas**:
   - `flutter analyze`: **0 issues found**.
   - Todos los archivos respetan el límite estricto de `< 300 líneas` y funciones `< 40 líneas`.

---

### 👤 USUARIO:
<USER_REQUEST>
Hola. Tras una auditoría forense completa de las 14 colecciones de la base de datos de V1, vamos a consolidar de forma definitiva todas las Entidades del Negocio (Paso 2.2) y los Contratos de Repositorio (Paso 2.3) en C:\Reparto-Manager-DEV (rama v2-clean-architecture).

Reglas estrictas: Dart puro (sin UI ni Firebase), inmutabilidad defensiva, multi-tenancy con tenantId, archivos < 300 líneas y funciones < 40 líneas.

Tu misión es verificar, actualizar y crear lo siguiente:
BLOQUE 1: CONSOLIDACIÓN DE ENTIDADES (lib/domain/entities/)
1. Actualizar ClientEntity (nickname, city, isOpenContinuous, groupId)
2. Crear ZoneEntity (cities)
3. Crear ClientGroupEntity (clientIds)
4. Crear PromotionEntity (requiredItems, discountPercentage, isEligible)
5. Actualizar ProductEntity y ProductVariant
6. Actualizar SaleEntity (ExchangeItemEntity, exchanges, appliedPromos, previousBalance, remainingBalance)
7. Actualizar PaymentEntity (soporte de cobro mixto cashPaid + transferPaid == amount)
8. TruckLoadEntity

BLOQUE 2: CONTRATOS DE REPOSITORIO (lib/domain/repositories/)
1. IClientRepository
2. IZoneRepository
3. IClientGroupRepository
4. IProductRepository
5. IPromotionRepository
6. ISaleRepository
7. IPaymentRepository
8. ITruckRepository
9. ILedgerRepository

BLOQUE 3: TESTS, VERIFICACIÓN Y CIERRE
</USER_REQUEST>

---

### 🤖 ASISTENTE:
Ejecución completa y consolidación forense de Entidades y Repositorios:

1. **Bloque 1: Entidades Consolidadas (`lib/domain/entities/`)**:
   - `ClientEntity`: Incorporados `nickname`, `city`, `isOpenContinuous`, `groupId` manteniendo `customPrices` indexado por `variantKey`.
   - `ZoneEntity`: Creada con lista inmutable `cities`.
   - `ClientGroupEntity`: Creada con lista inmutable `clientIds`.
   - `PromotionEntity`: Creada con `requiredItems` y método de evaluación de carrito `isEligible`.
   - `SaleItemEntity` y `ExchangeItemEntity`: Modularizados en archivo dedicado `sale_item_entity.dart` para cambios y devoluciones.
   - `SaleEntity`: Incorporados `exchanges`, `appliedPromos`, `previousBalance` y `remainingBalance` con validación de invariantes bancarios.
   - `PaymentEntity`: Incorporado desglose mixto `cashPaid` y `transferPaid` (`amount == cashPaid + transferPaid > 0`).

2. **Bloque 2: Contratos de Repositorio IoC (`lib/domain/repositories/`)**:
   - 9 interfaces abstractas puras con `tenantId` estricto, paginación (`limit`, `offset`) y retornos `Future<Result<T, DomainFailure>>`:
     * `IClientRepository`
     * `IZoneRepository`
     * `IClientGroupRepository`
     * `IProductRepository`
     * `IPromotionRepository`
     * `ISaleRepository`
     * `IPaymentRepository`
     * `ITruckRepository`
     * `ILedgerRepository`

3. **Bloque 3: Tests Unitarios y Verificación**:
   - Actualizado `business_entities_test.dart` y creado `repository_contracts_test.dart` con Fakes en memoria.
   - `flutter test`: **24/24 tests aprobados (100% éxito)**.
   - `flutter analyze`: **0 issues found** (0 errores, 0 warnings).
   - Todos los archivos respetan el límite estricto de `< 300 líneas` y funciones `< 40 líneas`.

---

### 👤 USUARIO:
<USER_REQUEST>
Llegamos al paso final y más importante de la FASE 2: Capa de Dominio Puro en C:\Reparto-Manager-DEV (rama v2-clean-architecture).

Tu misión es ejecutar formalmente el Paso 2.4: Casos de Uso (Interactors de Lógica de Negocio Pura).
Siguiendo Clean Architecture y el principio YAGNI estricto (Regla 13), implementaremos ÚNICAMENTE la lógica real y probada que existía en la operativa de V1.

LOS 18 CASOS DE USO REALES (lib/domain/usecases/)
1. ResolveProductPriceUseCase
2. DuplicateClientPricesUseCase
3. ApplyPromotionUseCase
4. LoadTruckStockUseCase
5. UnloadTruckStockUseCase
6. RegisterDamagedStockUseCase
7. ProcessSaleUseCase
8. UpdateSaleUseCase
9. CancelSaleUseCase
10. ResetZoneRouteUseCase
11. CalculateClientBalanceUseCase
12. RegisterPaymentUseCase
13. CancelPaymentUseCase
14. RecordManualAdjustmentUseCase
15. GenerateLedgerSnapshotUseCase
16. CreateGroupInvoiceUseCase
17. PayGroupInvoiceUseCase
18. GenerateCashSummaryUseCase

BATERÍA DE TESTS UNITARIOS (test/domain/usecases/)
CIERRE Y VERIFICACIÓN DE FASE 2
</USER_REQUEST>

---

### 🤖 ASISTENTE:
Ejecución completa y cierre definitivo de la Fase 2 (Paso 2.4):

1. **Los 18 Casos de Uso del Dominio Puro (`lib/domain/usecases/`)**:
   - Tipado funcional con `Future<Result<T, DomainFailure>> execute(...)`.
   - Dart puro, sin dependencias externas, respetando Inversión de Control e inyección de dependencias por repositorio.
   - Regla 9 Estricta: Prohibido forzar saldos a mano; `CalculateClientBalanceUseCase` suma eventos desde el último snapshot.
   - Partida doble en ventas: `ProcessSaleUseCase` asienta débito por venta y crédito por pago en el acto.
   - Restitución integral de stock y contra-asiento en `CancelSaleUseCase`.

2. **Batería de Pruebas Unitarias (`test/domain/usecases/`)**:
   - 4 archivos modulares (< 300 líneas c/u):
     * `pricing_and_promos_use_cases_test.dart`
     * `truck_use_cases_test.dart`
     * `sales_use_cases_test.dart`
     * `ledger_and_payments_use_cases_test.dart`
   - **41/41 tests aprobados (100% de éxito)**.
   - `flutter analyze`: **0 issues found** (cero errores, cero advertencias).
   - Todos los archivos del dominio y pruebas respetan `< 300 líneas` y funciones `< 40 líneas`.



