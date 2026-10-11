import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../../../shared/models/opportunity.dart';

/// OpportunityCache: the catalog lives in Hive and is refreshed from the
/// API when a connection is available.
class OpportunityRepository {
  List<Opportunity> all() => [
    for (final raw in LocalStore.box(Boxes.catalog).values) Opportunity.fromJson(raw as Map),
  ];

  Opportunity? byId(String id) {
    final raw = LocalStore.box(Boxes.catalog).get(id);
    return raw == null ? null : Opportunity.fromJson(raw as Map);
  }

  /// Pulls the latest catalog. Returns false (and keeps the cache) on any
  /// failure — the app never depends on this call.
  Future<bool> refresh(ApiClient api) async {
    try {
      final json = await api.get('/api/opportunities', auth: false);
      final items = (json['items'] as List).cast<Map>();
      final box = LocalStore.box(Boxes.catalog);
      for (final item in items) {
        await box.put(item['id'], item);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
