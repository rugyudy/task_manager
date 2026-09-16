import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 1分ごとに現在時刻を流すだけの Stream。「あとX分/時間」の表示を定期的に
/// 再計算させたいウィジェットが ref.watch するために使う。
final minuteTickerProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});
