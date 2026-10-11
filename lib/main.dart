import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/local_store.dart';
import 'shared/components/opportunity_cover.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Offline-first: storage is opened and seeded before the first frame,
  // nothing waits on the network.
  await LocalStore.init();
  await OpportunityPhotos.load();

  runApp(const ProviderScope(child: TifawtApp()));
}
