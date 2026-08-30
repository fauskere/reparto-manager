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
