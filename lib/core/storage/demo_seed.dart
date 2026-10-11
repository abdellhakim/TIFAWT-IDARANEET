import 'package:hive_flutter/hive_flutter.dart';

import '../authentication/password_hasher.dart';
import 'local_store.dart';

/// The fictional demo persona used in the jury walkthrough:
/// Chahd, 21, Bac, Taroudant — looking for a training, limited mobility.
///
/// Her questionnaire is pre-filled but not yet confirmed, so the demo shows
/// the profile step without retyping everything.
abstract final class DemoSeed {
  static const userId = 'demo-chahd';
  static const phone = '0600000000';
  static const email = 'chahd@tifawt.ma';
  static const password = '123456';

  static Future<void> ensure() async {
    final auth = Hive.box(Boxes.auth);
    if (auth.containsKey('user:$userId')) return;
    await _write();
  }

  static Future<void> reset() async {
    await LocalStore.wipeUser(userId);
    final queue = Hive.box(Boxes.syncQueue);
    for (final key in queue.keys.toList()) {
      final op = queue.get(key);
      if (op is Map && op['userId'] == userId) await queue.delete(key);
    }
    await _write();
  }

  static Future<void> _write() async {
    final auth = Hive.box(Boxes.auth);
    final salt = PasswordHasher.newSalt();
    await auth.put('user:$userId', {
      'id': userId,
      'name': 'شهد أمزيان',
      'nameLatin': 'Chahd Amzian',
      'phone': phone,
      'email': email,
      'role': 'youth',
      'salt': salt,
      'hash': PasswordHasher.hash(password, salt),
      'demo': true,
    });
    await auth.put('login:$phone', userId);
    await auth.put('login:$email', userId);

    await Hive.box(Boxes.profiles).put(userId, {
      'userId': userId,
      'age': 21,
      'sex': 'female',
      'province': 'taroudant',
      'commune': 'Taroudant',
      'situation': 'trainingSeeking',
      'education': 'bac',
      'lastDiploma': 'bac',
      'vocationalTraining': '',
      'objective': 'training',
      'interests': ['digital', 'commerce'],
      'skills': ['communication', 'languages'],
      'mobility': 'commune',
      'internetAccess': 'occasional',
      'connectionType': 'mobile3g',
      'availability': 'fullTime',
      'modality': 'any',
      'completed': false,
    });

    await Hive.box(Boxes.favorites).put(userId, ['op_metier_technique', 'op_competences_digitales']);

    await Hive.box(Boxes.documents).put(userId, [
      {'code': 'cin', 'ready': true},
      {'code': 'residence', 'ready': false},
      {'code': 'schoolCertificate', 'ready': true},
    ]);
  }
}
