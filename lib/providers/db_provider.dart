import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

/// main() で Isar.open() の結果を override して使う。
/// (アプリ起動時に一度だけ DB を開き、Provider に注入する設計)
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('main() で isarProvider.overrideWithValue が必要です');
});
