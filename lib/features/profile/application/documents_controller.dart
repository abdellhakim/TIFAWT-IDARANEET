import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../auth/application/auth_controller.dart';
import '../../synchronization/application/sync_manager.dart';
import '../../synchronization/domain/sync_operation.dart';
import '../domain/document_item.dart';

/// "Mes documents": a checklist of papers to prepare, kept offline.
class DocumentsController extends Notifier<List<DocumentItem>> {
  @override
  List<DocumentItem> build() {
    final user = ref.watch(authProvider);
    if (user == null) return const [];
    final raw = LocalStore.box(Boxes.documents).get(user.id) as List?;
    if (raw == null) {
      return const [DocumentItem(DocumentType.cin), DocumentItem(DocumentType.residence)];
    }
    return [for (final d in raw) DocumentItem.fromJson(d as Map)];
  }

  Future<void> toggle(DocumentType type) =>
      _save([for (final d in state) d.type == type ? DocumentItem(type, ready: !d.ready) : d]);

  Future<void> add(DocumentType type) async {
    if (state.any((d) => d.type == type)) return;
    await _save([...state, DocumentItem(type)]);
  }

  Future<void> _save(List<DocumentItem> items) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    state = items;
    final json = [for (final d in items) d.toJson()];
    await LocalStore.box(Boxes.documents).put(user.id, json);
    await ref
        .read(syncProvider.notifier)
        .enqueue(
          userId: user.id,
          entity: SyncEntity.document,
          operation: SyncOp.update,
          payload: {'documents': json},
        );
  }
}

final documentsProvider = NotifierProvider<DocumentsController, List<DocumentItem>>(DocumentsController.new);
