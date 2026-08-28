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
- **Estado**: Producción en `v2.9.85` 100% purgada y limpia.

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
