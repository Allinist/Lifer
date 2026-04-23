class DatabaseBlueprint {
  static const schemaVersion = 1;

  static const coreTables = <String>[
    'categories',
    'units',
    'products',
    'purchase_channels',
    'price_records',
    'storage_locations',
    'stock_batches',
    'stock_batch_locations',
    'restock_records',
    'consumption_records',
    'durable_usage_periods',
    'reminder_rules',
    'reminder_events',
    'product_note_links',
    'app_settings',
  ];
}
