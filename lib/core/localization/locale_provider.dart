import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_store.dart';
import 'app_language.dart';
import 'app_strings.dart';

class LocaleNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.fromCode(LocalStore.box(Boxes.settings).get('language') as String?);

  Future<void> set(AppLanguage language) async {
    state = language;
    await LocalStore.box(Boxes.settings).put('language', language.code);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, AppLanguage>(LocaleNotifier.new);

final stringsProvider = Provider<AppStrings>((ref) => AppStrings(ref.watch(localeProvider)));
