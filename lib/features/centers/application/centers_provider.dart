import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../../shared/models/support_center.dart';

final centersProvider = Provider<List<SupportCenter>>(
  (ref) =>
      [for (final raw in LocalStore.box(Boxes.centers).values) SupportCenter.fromJson(raw as Map)]
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)),
);
