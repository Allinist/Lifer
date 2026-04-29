import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/app/theme/theme_palette.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/settings/application/app_icon_service.dart';
import 'package:lifer/features/settings/application/settings_data_io_service.dart';

const defaultLogoAsset = 'assets/logo/Lifer.png';
const alternateLogoAsset = 'assets/logo/Logo.png';

const _logoSplit = '||';

final appSettingsStreamProvider = StreamProvider<AppSetting?>((ref) {
  return ref.watch(settingsDaoProvider).watchSettings();
});

Map<String, String> _decodeLogoBundle(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return {'icon': defaultLogoAsset, 'splash': defaultLogoAsset};
  }
  final parts = raw.split(_logoSplit);
  if (parts.length == 2) {
    return {
      'icon': parts[0].trim().isEmpty ? defaultLogoAsset : parts[0].trim(),
      'splash': parts[1].trim().isEmpty ? defaultLogoAsset : parts[1].trim(),
    };
  }
  return {'icon': raw, 'splash': raw};
}

String _encodeLogoBundle({
  required String iconAssetPath,
  required String splashAssetPath,
}) {
  return '$iconAssetPath$_logoSplit$splashAssetPath';
}

final currentAppIconAssetProvider = Provider<String>((ref) {
  final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
  return _decodeLogoBundle(settings?.logoAssetPath)['icon'] ?? defaultLogoAsset;
});

final currentSplashLogoAssetProvider = Provider<String>((ref) {
  final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
  return _decodeLogoBundle(settings?.logoAssetPath)['splash'] ?? defaultLogoAsset;
});

final currentThemePaletteKeyProvider = Provider<String>((ref) {
  final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
  return resolveThemePalette(settings?.themeMode).key;
});

final settingsActionsProvider = Provider<SettingsActions>((ref) {
  return SettingsActions(
    ref.watch(appDatabaseProvider),
    ref.watch(settingsDaoProvider),
    AppIconService(),
    SettingsDataIoService(ref.watch(appDatabaseProvider)),
  );
});

final appDocumentsDirectoryPathProvider = FutureProvider<String>((ref) {
  return SettingsDataIoService(ref.watch(appDatabaseProvider)).getDocumentsDirectoryPath();
});

class SettingsActions {
  SettingsActions(this._db, this._dao, this._appIconService, this._dataIoService);

  final AppDatabase _db;
  final SettingsDao _dao;
  final AppIconService _appIconService;
  final SettingsDataIoService _dataIoService;

  Future<void> saveNotificationsEnabled(bool enabled) {
    return _dao.upsertSettings(
      AppSettingsCompanion(
        id: const Value(1),
        notificationsEnabled: Value(enabled),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> saveLanguageCode(String languageCode) {
    final normalized = languageCode.trim();
    return _dao.upsertSettings(
      AppSettingsCompanion(
        id: const Value(1),
        languageCode: Value(normalized.isEmpty ? 'zh-CN' : normalized),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> saveCurrencyCode(String currencyCode) {
    final normalized = currencyCode.trim().toUpperCase();
    return _dao.upsertSettings(
      AppSettingsCompanion(
        id: const Value(1),
        currencyCode: Value(normalized.isEmpty ? 'CNY' : normalized),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> saveThemeMode(String themeMode) {
    final normalized = resolveThemePalette(themeMode).key;
    return _dao.upsertSettings(
      AppSettingsCompanion(
        id: const Value(1),
        themeMode: Value(normalized),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> saveAppIconAsset(String assetPath) async {
    final settings = await (_db.select(_db.appSettings)..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
    final bundle = _decodeLogoBundle(settings?.logoAssetPath);
    final iconKey = assetPath == alternateLogoAsset ? alternateAppIconKey : defaultAppIconKey;
    await _appIconService.setAppIcon(iconKey);
    await _dao.upsertSettings(
      AppSettingsCompanion(
        id: const Value(1),
        logoAssetPath: Value(
          _encodeLogoBundle(
            iconAssetPath: assetPath,
            splashAssetPath: bundle['splash'] ?? defaultLogoAsset,
          ),
        ),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> saveSplashLogoAsset(String assetPath) async {
    final settings = await (_db.select(_db.appSettings)..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
    final bundle = _decodeLogoBundle(settings?.logoAssetPath);
    await _dao.upsertSettings(
      AppSettingsCompanion(
        id: const Value(1),
        logoAssetPath: Value(
          _encodeLogoBundle(
            iconAssetPath: bundle['icon'] ?? defaultLogoAsset,
            splashAssetPath: assetPath,
          ),
        ),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<String> exportJson() {
    return _dataIoService.exportJson();
  }

  Future<String> exportJsonToPath(String outputFilePath) {
    return _dataIoService.exportJsonToPath(outputFilePath);
  }

  Future<String> getDocumentsDirectoryPath() {
    return _dataIoService.getDocumentsDirectoryPath();
  }

  Future<String> importJson() async {
    final path = await _dataIoService.importJson();
    final settings = await (_db.select(_db.appSettings)..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
    final assetPath = _decodeLogoBundle(settings?.logoAssetPath)['icon'] ?? defaultLogoAsset;
    await _appIconService.setAppIcon(
      assetPath == alternateLogoAsset ? alternateAppIconKey : defaultAppIconKey,
    );
    return path;
  }

  Future<String> importJsonFromPath(String sourceFilePath) async {
    final path = await _dataIoService.importJsonFromPath(sourceFilePath);
    final settings = await (_db.select(_db.appSettings)..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
    final assetPath = _decodeLogoBundle(settings?.logoAssetPath)['icon'] ?? defaultLogoAsset;
    await _appIconService.setAppIcon(
      assetPath == alternateLogoAsset ? alternateAppIconKey : defaultAppIconKey,
    );
    return path;
  }
}
