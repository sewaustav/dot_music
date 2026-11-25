import 'package:dot_music/core/config.dart';
import 'package:dot_music/features/pages/player/service.dart';
import 'package:flutter/material.dart';

class PlayerStateListener {
  static final PlayerStateListener _instance = PlayerStateListener._internal();
  factory PlayerStateListener() => _instance;

  PlayerLogic? _playerLogic;
  final List<VoidCallback> _listeners = [];

  PlayerStateListener._internal();

  void registerPlayer(PlayerLogic playerLogic) {
    if (identical(_playerLogic, playerLogic)) return;

    final previous = _playerLogic;
    previous?.removeListener(_notifyListeners);
    // Старый PlayerLogic больше не нужен: подписки и колбэк завершения трека
    // переходят к новому плееру. Иначе они копятся при каждом открытии плеера.
    previous?.dispose();

    _playerLogic = playerLogic;
    _playerLogic!.addListener(_notifyListeners);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyListeners();
    });
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    final listeners = List<VoidCallback>.from(_listeners);
    for (final listener in listeners) {
      try {
        listener();
      } catch (e) {
        logger.e('Error in player listener', error: e);
      }
    }
  }

  void dispose() {
    _playerLogic?.removeListener(_notifyListeners);
    _listeners.clear();
  }

  bool isSameTrack(String path, int index, int playlist) {
    if (_playerLogic == null) return false;

    final currentPath = _playerLogic!.currentSong?['path'];
    final currentIndex = _playerLogic!.currentSongIndex;
    final currentPlaylist = _playerLogic!.playlist;

    return currentPath == path &&
        currentIndex == index &&
        currentPlaylist == playlist;
  }

  // 🎵 НОВЫЕ МЕТОДЫ для управления плеером
  Future<void> playNext() async {
    if (_playerLogic != null) {
      await _playerLogic!.playNextSong();
    }
  }

  Future<void> playPrevious() async {
    if (_playerLogic != null) {
      await _playerLogic!.playPreviousSong();
    }
  }

  Future<void> togglePlayPause() async {
    if (_playerLogic != null) {
      await _playerLogic!.togglePlayPause();
    }
  }

  // Getters
  bool get isPlaying => _playerLogic?.isPlaying ?? false;
  String get currentTitle => _playerLogic?.currentTitle ?? '';
  String get currentArtist => _playerLogic?.currentArtist ?? '';
  Duration get currentPosition =>
      _playerLogic?.currentPosition ?? Duration.zero;
  Duration get totalDuration => _playerLogic?.totalDuration ?? Duration.zero;
  Map<String, dynamic>? get currentSong => _playerLogic?.currentSong;
  PlayerLogic? get playerLogic => _playerLogic;
  bool get hasPlayer => _playerLogic != null;
}
