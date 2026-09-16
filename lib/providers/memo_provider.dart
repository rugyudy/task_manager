import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/memo.dart';
import 'db_provider.dart';

final memosStreamProvider = StreamProvider<List<Memo>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.memos.where().sortByUpdatedAtDesc().watch(fireImmediately: true);
});

class MemoController {
  MemoController(this._isar);
  final Isar _isar;

  Future<int> addMemo({
    required String title,
    required String content,
    List<String> tags = const [],
  }) {
    final memo = Memo()
      ..title = title
      ..content = content
      ..tags = tags
      ..updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.memos.put(memo));
  }

  Future<void> updateMemo(Memo memo) {
    memo.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.memos.put(memo));
  }

  Future<void> deleteMemo(int id) {
    return _isar.writeTxn(() => _isar.memos.delete(id));
  }
}

final memoControllerProvider = Provider<MemoController>((ref) {
  return MemoController(ref.watch(isarProvider));
});
