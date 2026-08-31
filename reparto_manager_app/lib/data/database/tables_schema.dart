// lib/data/database/tables_schema.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Multi-Tenancy Big Tech

class TablesSchema {
  static const int databaseVersion = 1;

  static const List<String> createTablesQueries = [
    '''
    CREATE TABLE IF NOT EXISTS clients (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      name TEXT NOT NULL,
      nickname TEXT,
      phone TEXT,
      city TEXT,
      address TEXT,
      zoneId TEXT,
      clientType TEXT NOT NULL,
      visitStatus TEXT NOT NULL,
      isStore INTEGER NOT NULL DEFAULT 0,
      isOpenContinuous INTEGER NOT NULL DEFAULT 0,
      groupId TEXT,
      customPricesJson TEXT,
      balanceCents INTEGER NOT NULL DEFAULT 0,
      debtLimitCents INTEGER NOT NULL DEFAULT 0,
      isActive INTEGER NOT NULL DEFAULT 1,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS products (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      barcode TEXT,
      imageUrl TEXT,
      variantsJson TEXT NOT NULL,
      isActive INTEGER NOT NULL DEFAULT 1,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS price_history (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      productId TEXT NOT NULL,
      productName TEXT NOT NULL,
      variantName TEXT NOT NULL,
      oldPriceCents INTEGER NOT NULL,
      newPriceCents INTEGER NOT NULL,
      changedAtUtc TEXT NOT NULL,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS sales (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      ticketNumber INTEGER NOT NULL,
      dateUtc TEXT NOT NULL,
      clientId TEXT NOT NULL,
      clientName TEXT NOT NULL,
      itemsJson TEXT NOT NULL,
      exchangesJson TEXT,
      appliedPromosJson TEXT,
      subtotalCents INTEGER NOT NULL,
      totalDiscountCents INTEGER NOT NULL,
      totalCents INTEGER NOT NULL,
      paymentMethod TEXT NOT NULL,
      cashPaidCents INTEGER NOT NULL,
      transferPaidCents INTEGER NOT NULL,
      debtGeneratedCents INTEGER NOT NULL,
      previousBalanceCents INTEGER NOT NULL,
      remainingBalanceCents INTEGER NOT NULL,
      isCancelled INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS payments (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      receiptNumber INTEGER NOT NULL,
      dateUtc TEXT NOT NULL,
      clientId TEXT NOT NULL,
      amountCents INTEGER NOT NULL,
      cashPaidCents INTEGER NOT NULL,
      transferPaidCents INTEGER NOT NULL,
      previousBalanceCents INTEGER NOT NULL,
      remainingBalanceCents INTEGER NOT NULL,
      notes TEXT,
      isCancelled INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS truck_loads (
      truckId TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      dateUtc TEXT NOT NULL,
      inventoryJson TEXT NOT NULL,
      damagedItemsJson TEXT,
      PRIMARY KEY (tenantId, truckId)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS ledger_entries (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      clientId TEXT NOT NULL,
      dateUtc TEXT NOT NULL,
      type TEXT NOT NULL,
      amountCents INTEGER NOT NULL,
      balanceImpactCents INTEGER NOT NULL,
      description TEXT NOT NULL,
      documentReference TEXT,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS ledger_snapshots (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      clientId TEXT NOT NULL,
      dateUtc TEXT NOT NULL,
      closingBalanceCents INTEGER NOT NULL,
      entryCount INTEGER NOT NULL,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS cash_summaries (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      dateUtc TEXT NOT NULL,
      closedAtUtc TEXT NOT NULL,
      salesCashCents INTEGER NOT NULL,
      salesTransferCents INTEGER NOT NULL,
      paymentsCashCents INTEGER NOT NULL,
      paymentsTransferCents INTEGER NOT NULL,
      totalCashCents INTEGER NOT NULL,
      totalTransferCents INTEGER NOT NULL,
      totalRevenueCents INTEGER NOT NULL,
      debtGeneratedCents INTEGER NOT NULL,
      clientBreakdownJson TEXT NOT NULL,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS zones (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      name TEXT NOT NULL,
      citiesJson TEXT NOT NULL,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS client_groups (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      name TEXT NOT NULL,
      clientIdsJson TEXT NOT NULL,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS group_invoices (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      groupId TEXT NOT NULL,
      totalAmountCents INTEGER NOT NULL,
      invoicedAtUtc TEXT NOT NULL,
      saleIdsJson TEXT NOT NULL,
      status TEXT NOT NULL,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS promotions (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      name TEXT NOT NULL,
      requiredItemsJson TEXT NOT NULL,
      discountPercentage REAL NOT NULL,
      isActive INTEGER NOT NULL DEFAULT 1,
      PRIMARY KEY (tenantId, id)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT NOT NULL,
      value TEXT,
      tenantId TEXT NOT NULL,
      PRIMARY KEY (tenantId, key)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT NOT NULL,
      tenantId TEXT NOT NULL,
      collectionName TEXT NOT NULL,
      documentId TEXT NOT NULL,
      operation TEXT NOT NULL,
      payloadJson TEXT NOT NULL,
      createdAtUtc TEXT NOT NULL,
      status TEXT NOT NULL,
      PRIMARY KEY (tenantId, id)
    );
    ''',
  ];

  static const List<String> createIndexesQueries = [
    'CREATE INDEX IF NOT EXISTS idx_clients_tenant_zone ON clients(tenantId, zoneId);',
    'CREATE INDEX IF NOT EXISTS idx_clients_tenant_name ON clients(tenantId, name);',
    'CREATE INDEX IF NOT EXISTS idx_sales_tenant_date ON sales(tenantId, dateUtc);',
    'CREATE INDEX IF NOT EXISTS idx_sales_tenant_client ON sales(tenantId, clientId);',
    'CREATE INDEX IF NOT EXISTS idx_payments_tenant_date ON payments(tenantId, dateUtc);',
    'CREATE INDEX IF NOT EXISTS idx_payments_tenant_client ON payments(tenantId, clientId);',
    'CREATE INDEX IF NOT EXISTS idx_ledger_tenant_client_date ON ledger_entries(tenantId, clientId, dateUtc);',
    'CREATE INDEX IF NOT EXISTS idx_sync_tenant_status ON sync_queue(tenantId, status);',
  ];
}
