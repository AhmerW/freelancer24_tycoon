import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/game_notice.dart';
import 'package:freelancer24_tycoon/game/sfx.dart';

/// The notices currently on screen. Expired notices remove themselves.
class AlertCubit extends Cubit<List<GameNotice>> {
  static const maxVisible = 4;

  late final StreamSubscription<GameNotice> _sub;
  final Map<int, Timer> _timers = {};

  AlertCubit(Stream<GameNotice> notices) : super(const []) {
    _sub = notices.listen(push);
  }

  void push(GameNotice notice) {
    if (isClosed) return;
    if (notice.kind == NoticeKind.error) {
      Sfx.instance.play(Sound.error);
    } else if (notice.chime) {
      Sfx.instance.play(Sound.ding);
    }
    final visible = [...state, notice];
    while (visible.length > maxVisible) {
      _timers.remove(visible.removeAt(0).id)?.cancel();
    }
    emit(List.unmodifiable(visible));
    if (notice.lifetime != null) {
      _timers[notice.id] = Timer(notice.lifetime!, () => dismiss(notice.id));
    }
  }

  void dismiss(int id) {
    if (isClosed) return;
    _timers.remove(id)?.cancel();
    emit(List.unmodifiable(state.where((n) => n.id != id)));
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    for (final t in _timers.values) {
      t.cancel();
    }
    return super.close();
  }
}
