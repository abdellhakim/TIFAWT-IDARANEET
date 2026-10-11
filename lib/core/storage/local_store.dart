import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'demo_seed.dart';
import 'secure_store.dart';

/// Hive boxes. Anything personal is encrypted (AES-256, key in the
/// platform keystore); public catalog data is not.
abstract final class Boxes {
  static const settings = 'tf_settings';
  static const catalog = 'tf_catalog';
  static const centers = 'tf_centers';
  static const knowledge = 'tf_knowledge';

  static const auth = 'tf_auth';
  static const profiles = 'tf_profiles';
  static const recommendations = 'tf_recommendations';
  static const journey = 'tf_journey';
  static const badges = 'tf_badges';
  static const favorites = 'tf_favorites';
  static const documents = 'tf_documents';
  static const chat = 'tf_chat';
  static const syncQueue = 'tf_sync_queue';

  static const plain = [settings, catalog, centers, knowledge];
  static const encrypted = [
    auth,
    profiles,
    recommendations,
    journey,
    badges,
    favorites,
    documents,
    chat,
    syncQueue,
  ];

  /// Boxes holding one entry per user id.
  static const perUser = [profiles, recommendations, journey, badges, favorites, documents, chat];
}

abstract final class LocalStore {
  static Future<void> init() async {
    await Hive.initFlutter('tifawt');
    final cipher = HiveAesCipher(await SecureStore.instance.hiveEncryptionKey());

    await Future.wait([
      for (final name in Boxes.plain) Hive.openBox(name),
      for (final name in Boxes.encrypted) Hive.openBox(name, encryptionCipher: cipher),
    ]);

    await _seedCatalog();
    await DemoSeed.ensure();
  }

  static Box box(String name) => Hive.box(name);

  static const _catalogs = {
    Boxes.catalog: 'assets/data/opportunities.json',
    Boxes.centers: 'assets/data/centers.json',
  };

  /// Copies the bundled catalog into Hive when the bundled version is newer
  /// than the cached one, so a fresh install is fully usable offline.
  static Future<void> _seedCatalog() async {
    final settings = box(Boxes.settings);

    for (final MapEntry(key: boxName, value: path) in _catalogs.entries) {
      final json = jsonDecode(await rootBundle.loadString(path)) as Map;
      final version = json['version'] as int;
      if ((settings.get('$boxName.version') as int? ?? 0) >= version) continue;

      final target = box(boxName);
      await target.clear();
      for (final item in (json['items'] as List).cast<Map>()) {
        await target.put(item['id'], item);
      }
      await settings.put('$boxName.version', version);
    }

    final kb = jsonDecode(await rootBundle.loadString('assets/data/assistant_knowledge.json')) as Map;
    final kbVersion = kb['version'] as int;
    if ((settings.get('${Boxes.knowledge}.version') as int? ?? 0) < kbVersion) {
      final knowledge = box(Boxes.knowledge);
      await knowledge.clear();
      for (final entry in (kb['faq'] as List).cast<Map>()) {
        await knowledge.put(entry['id'], entry);
      }
      await settings.put('${Boxes.knowledge}.version', kbVersion);
    }
  }

  /// Removes everything stored for [userId] (right to erasure).
  static Future<void> wipeUser(String userId) async {
    for (final name in Boxes.perUser) {
      await box(name).delete(userId);
    }
  }
}
