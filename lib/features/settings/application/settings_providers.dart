import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/settings/application/app_icon_service.dart';
import 'package:lifer/features/settings/application/settings_data_io_service.dart';

const defaultLogoAsset = 'assets/logo/Lifer.png';
const alternateLogoAsset = 'assets/logo/Logo.png';

final appSettingsStreamProvider = StreamProvider<AppSetting?>((ref) {
  return ref.watch(settingsDaoProvider).watchSettings();
});

final currentLogoAssetProvider = Provider<String>((ref) {
  final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
  return settings?.logoAssetPath ?? defaultLogoAsset;
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

  Future<void> saveLogoAsset(String assetPath) async {
    final iconKey = assetPath == alternateLogoAsset ? alternateAppIconKey : defaultAppIconKey;
    await _appIconService.setAppIcon(iconKey);
    await _dao.upsertSettings(
      AppSettingsCompanion(
        id: const Value(1),
        logoAssetPath: Value(assetPath),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<String> exportJson() {
    return _dataIoService.exportJson();
  }

  Future<String> getDocumentsDirectoryPath() {
    return _dataIoService.getDocumentsDirectoryPath();
  }

  Future<String> importJson() async {
    final path = await _dataIoService.importJson();
    final settings = await (_db.select(_db.appSettings)..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
    final assetPath = settings?.logoAssetPath ?? defaultLogoAsset;
    await _appIconService.setAppIcon(
      assetPath == alternateLogoAsset ? alternateAppIconKey : defaultAppIconKey,
    );
    return path;
  }
}
