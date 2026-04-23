import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get color => text().nullable()();
  TextColumn get iconUri => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {parentId, name},
      ];
}

class Units extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get symbol => text()();
  TextColumn get unitType => text()();
  TextColumn get baseUnitSymbol => text().nullable()();
  RealColumn get toBaseFactor => real().nullable()();
  BoolColumn get allowDecimal => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get name => text()();
  TextColumn get alias => text().nullable()();
  TextColumn get productType => text()();
  TextColumn get logoUri => text().nullable()();
  TextColumn get unitId => text().nullable().references(Units, #id)();
  TextColumn get brand => text().nullable()();
  TextColumn get skuText => text().nullable()();
  IntColumn get expectedPriceMinor => integer().nullable()();
  TextColumn get currencyCode => text().nullable()();
  IntColumn get defaultShelfLifeDays => integer().nullable()();
  BoolColumn get isPinnedHome => boolean().withDefault(const Constant(false))();
  IntColumn get homeSortOrder => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get nutritionTagsJson => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PurchaseChannels extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get channelType => text()();
  TextColumn get url => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PriceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get channelId => text().nullable().references(PurchaseChannels, #id)();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unitId => text().nullable().references(Units, #id)();
  IntColumn get unitPriceMinor => integer().nullable()();
  IntColumn get purchasedAt => integer()();
  TextColumn get sourceType => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StorageLocations extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable().references(StorageLocations, #id)();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StockBatches extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get sourcePriceRecordId => text().nullable().references(PriceRecords, #id)();
  TextColumn get channelId => text().nullable().references(PurchaseChannels, #id)();
  RealColumn get totalQuantity => real().check(totalQuantity.isBiggerThanValue(0))();
  RealColumn get remainingQuantity => real()();
  TextColumn get unitId => text().references(Units, #id)();
  IntColumn get productionDate => integer().nullable()();
  IntColumn get purchasedAt => integer().nullable()();
  IntColumn get expiryDate => integer().nullable()();
  IntColumn get openedAt => integer().nullable()();
  TextColumn get batchLabel => text().nullable()();
  TextColumn get storageNotes => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (remaining_quantity >= 0 AND remaining_quantity <= total_quantity)',
      ];
}

class StockBatchLocations extends Table {
  TextColumn get id => text()();
  TextColumn get batchId => text().references(StockBatches, #id)();
  TextColumn get locationId => text().references(StorageLocations, #id)();
  RealColumn get quantity => real().check(quantity.isBiggerOrEqualValue(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RestockRecords extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get batchId => text().nullable().references(StockBatches, #id)();
  TextColumn get priceRecordId => text().nullable().references(PriceRecords, #id)();
  RealColumn get quantity => real()();
  TextColumn get unitId => text().references(Units, #id)();
  IntColumn get occurredAt => integer()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ConsumptionRecords extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get batchId => text().nullable().references(StockBatches, #id)();
  RealColumn get quantity => real().check(quantity.isBiggerThanValue(0))();
  TextColumn get unitId => text().references(Units, #id)();
  IntColumn get occurredAt => integer()();
  TextColumn get usageType => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DurableUsagePeriods extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get priceRecordId => text().nullable().references(PriceRecords, #id)();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer().nullable()();
  IntColumn get purchasePriceMinor => integer().nullable()();
  TextColumn get currencyCode => text().nullable()();
  IntColumn get averageDailyCostMinor => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReminderRules extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get ruleType => text()();
  TextColumn get thresholdType => text()();
  RealColumn get thresholdValue => real().nullable()();
  TextColumn get notifyTimeText => text().nullable()();
  IntColumn get leadTimeDays => integer().nullable()();
  IntColumn get leadTimeHours => integer().nullable()();
  TextColumn get repeatMode => text()();
  IntColumn get repeatIntervalHours => integer().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReminderEvents extends Table {
  TextColumn get id => text()();
  TextColumn get ruleId => text().references(ReminderRules, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get batchId => text().nullable().references(StockBatches, #id)();
  TextColumn get eventType => text()();
  IntColumn get urgencyScore => integer()();
  IntColumn get dueAt => integer().nullable()();
  IntColumn get notifiedAt => integer().nullable()();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
  IntColumn get resolvedAt => integer().nullable()();
  TextColumn get snapshotJson => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProductNoteLinks extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get title => text()();
  TextColumn get linkType => text()();
  TextColumn get uri => text().nullable()();
  TextColumn get obsidianPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  IntColumn get id => integer().check(id.equals(1))();
  TextColumn get languageCode => text().nullable()();
  TextColumn get currencyCode => text().nullable()();
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get themeMode => text().nullable()();
  TextColumn get logoAssetPath => text().nullable()();
  TextColumn get obsidianVaultPath => text().nullable()();
  TextColumn get obsidianUriScheme => text().nullable()();
  BoolColumn get exportEncryptionEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
