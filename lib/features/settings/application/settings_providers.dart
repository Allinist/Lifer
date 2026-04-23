import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';

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
  return SettingsActions(ref.watch(settingsDaoProvider));
});

class SettingsActions {
  SettingsActions(this._dao);

  final SettingsDao _dao;

  Future<void> saveLogoAsset(String assetPath) {
    return _dao.upsertSettings(
      AppSettingsCompanion(
        id: const Value(1),
        logoAssetPath: Value(assetPath),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
