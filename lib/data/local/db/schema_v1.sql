PRAGMA foreign_keys = ON;

CREATE TABLE categories (
  id TEXT PRIMARY KEY NOT NULL,
  parent_id TEXT NULL REFERENCES categories(id),
  name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0,
  color TEXT NULL,
  icon_uri TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(parent_id, name)
);

CREATE TABLE units (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  symbol TEXT NOT NULL,
  unit_type TEXT NOT NULL,
  base_unit_symbol TEXT NULL,
  to_base_factor REAL NULL,
  allow_decimal INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE products (
  id TEXT PRIMARY KEY NOT NULL,
  category_id TEXT NOT NULL REFERENCES categories(id),
  name TEXT NOT NULL,
  alias TEXT NULL,
  product_type TEXT NOT NULL,
  logo_uri TEXT NULL,
  unit_id TEXT NULL REFERENCES units(id),
  brand TEXT NULL,
  sku_text TEXT NULL,
  expected_price_minor INTEGER NULL,
  currency_code TEXT NULL,
  default_shelf_life_days INTEGER NULL,
  is_pinned_home INTEGER NOT NULL DEFAULT 0,
  home_sort_order INTEGER NULL,
  is_archived INTEGER NOT NULL DEFAULT 0,
  notes TEXT NULL,
  nutrition_tags_json TEXT NULL,
  metadata_json TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE purchase_channels (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  channel_type TEXT NOT NULL,
  url TEXT NULL,
  address TEXT NULL,
  latitude REAL NULL,
  longitude REAL NULL,
  notes TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE price_records (
  id TEXT PRIMARY KEY NOT NULL,
  product_id TEXT NOT NULL REFERENCES products(id),
  channel_id TEXT NULL REFERENCES purchase_channels(id),
  amount_minor INTEGER NOT NULL,
  currency_code TEXT NOT NULL,
  quantity REAL NULL,
  unit_id TEXT NULL REFERENCES units(id),
  unit_price_minor INTEGER NULL,
  purchased_at INTEGER NOT NULL,
  source_type TEXT NULL,
  notes TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE storage_locations (
  id TEXT PRIMARY KEY NOT NULL,
  parent_id TEXT NULL REFERENCES storage_locations(id),
  name TEXT NOT NULL,
  notes TEXT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE stock_batches (
  id TEXT PRIMARY KEY NOT NULL,
  product_id TEXT NOT NULL REFERENCES products(id),
  source_price_record_id TEXT NULL REFERENCES price_records(id),
  channel_id TEXT NULL REFERENCES purchase_channels(id),
  total_quantity REAL NOT NULL CHECK(total_quantity > 0),
  remaining_quantity REAL NOT NULL CHECK(remaining_quantity >= 0 AND remaining_quantity <= total_quantity),
  unit_id TEXT NOT NULL REFERENCES units(id),
  production_date INTEGER NULL,
  purchased_at INTEGER NULL,
  expiry_date INTEGER NULL,
  opened_at INTEGER NULL,
  batch_label TEXT NULL,
  storage_notes TEXT NULL,
  is_archived INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE stock_batch_locations (
  id TEXT PRIMARY KEY NOT NULL,
  batch_id TEXT NOT NULL REFERENCES stock_batches(id),
  location_id TEXT NOT NULL REFERENCES storage_locations(id),
  quantity REAL NOT NULL CHECK(quantity >= 0),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE restock_records (
  id TEXT PRIMARY KEY NOT NULL,
  product_id TEXT NOT NULL REFERENCES products(id),
  batch_id TEXT NULL REFERENCES stock_batches(id),
  price_record_id TEXT NULL REFERENCES price_records(id),
  quantity REAL NOT NULL,
  unit_id TEXT NOT NULL REFERENCES units(id),
  occurred_at INTEGER NOT NULL,
  notes TEXT NULL,
  created_at INTEGER NOT NULL
);

CREATE TABLE consumption_records (
  id TEXT PRIMARY KEY NOT NULL,
  product_id TEXT NOT NULL REFERENCES products(id),
  batch_id TEXT NULL REFERENCES stock_batches(id),
  quantity REAL NOT NULL CHECK(quantity > 0),
  unit_id TEXT NOT NULL REFERENCES units(id),
  occurred_at INTEGER NOT NULL,
  usage_type TEXT NOT NULL,
  notes TEXT NULL,
  created_at INTEGER NOT NULL
);

CREATE TABLE durable_usage_periods (
  id TEXT PRIMARY KEY NOT NULL,
  product_id TEXT NOT NULL REFERENCES products(id),
  price_record_id TEXT NULL REFERENCES price_records(id),
  start_at INTEGER NOT NULL,
  end_at INTEGER NULL,
  purchase_price_minor INTEGER NULL,
  currency_code TEXT NULL,
  average_daily_cost_minor INTEGER NULL,
  notes TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE reminder_rules (
  id TEXT PRIMARY KEY NOT NULL,
  product_id TEXT NOT NULL REFERENCES products(id),
  rule_type TEXT NOT NULL,
  threshold_type TEXT NOT NULL,
  threshold_value REAL NULL,
  notify_time_text TEXT NULL,
  lead_time_days INTEGER NULL,
  lead_time_hours INTEGER NULL,
  repeat_mode TEXT NOT NULL,
  repeat_interval_hours INTEGER NULL,
  is_enabled INTEGER NOT NULL DEFAULT 1,
  priority INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE reminder_events (
  id TEXT PRIMARY KEY NOT NULL,
  rule_id TEXT NOT NULL REFERENCES reminder_rules(id),
  product_id TEXT NOT NULL REFERENCES products(id),
  batch_id TEXT NULL REFERENCES stock_batches(id),
  event_type TEXT NOT NULL,
  urgency_score INTEGER NOT NULL,
  due_at INTEGER NULL,
  notified_at INTEGER NULL,
  is_resolved INTEGER NOT NULL DEFAULT 0,
  resolved_at INTEGER NULL,
  snapshot_json TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE product_note_links (
  id TEXT PRIMARY KEY NOT NULL,
  product_id TEXT NOT NULL REFERENCES products(id),
  title TEXT NOT NULL,
  link_type TEXT NOT NULL,
  uri TEXT NULL,
  obsidian_path TEXT NULL,
  notes TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE app_settings (
  id INTEGER PRIMARY KEY NOT NULL CHECK(id = 1),
  language_code TEXT NULL,
  currency_code TEXT NULL,
  notifications_enabled INTEGER NOT NULL DEFAULT 1,
  theme_mode TEXT NULL,
  logo_asset_path TEXT NULL,
  obsidian_vault_path TEXT NULL,
  obsidian_uri_scheme TEXT NULL,
  export_encryption_enabled INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_categories_parent_sort ON categories(parent_id, sort_order);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_type ON products(product_type);
CREATE INDEX idx_products_home ON products(is_pinned_home, home_sort_order);
CREATE INDEX idx_price_records_product_time ON price_records(product_id, purchased_at DESC);
CREATE INDEX idx_price_records_product_channel_time ON price_records(product_id, channel_id, purchased_at DESC);
CREATE INDEX idx_storage_locations_parent ON storage_locations(parent_id, sort_order);
CREATE INDEX idx_stock_batches_product ON stock_batches(product_id);
CREATE INDEX idx_stock_batches_expiry ON stock_batches(expiry_date);
CREATE INDEX idx_stock_batches_product_expiry ON stock_batches(product_id, expiry_date);
CREATE INDEX idx_restock_records_product_time ON restock_records(product_id, occurred_at DESC);
CREATE INDEX idx_consumption_records_product_time ON consumption_records(product_id, occurred_at DESC);
CREATE INDEX idx_durable_usage_periods_product_time ON durable_usage_periods(product_id, start_at DESC);
CREATE INDEX idx_reminder_rules_product ON reminder_rules(product_id);
CREATE INDEX idx_reminder_events_active ON reminder_events(is_resolved, urgency_score DESC, due_at ASC);
