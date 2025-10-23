import 'package:dot_music/features/pages/player/service.dart';

final playerLogicHolder = PlayerLogicHolder();

class PlayerLogicHolder {
  PlayerLogic? _logic;

  PlayerLogic get logic {
    _logic ??= PlayerLogic(
      refreshUI: () {}, 
      refreshBtn: (_) {},
      initialIndex: 0,
      playlist: 0,
    );
    return _logic!;
  }

  void set(PlayerLogic logic) {
    _logic = logic;
  }

  bool get isInitialized => _logic != null;
}
