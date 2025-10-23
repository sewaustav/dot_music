import 'dart:ui';

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
    _playerLogic?.removeListener(_notifyListeners);
    _playerLogic = playerLogic;
    _playerLogic?.addListener(_notifyListeners);

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
  
  bool get isPlaying => _playerLogic?.isPlaying ?? false;
  String get currentTitle => _playerLogic?.currentTitle ?? '';
  String get currentArtist => _playerLogic?.currentArtist ?? '';
  Duration get currentPosition => _playerLogic?.currentPosition ?? Duration.zero;
  Duration get totalDuration => _playerLogic?.totalDuration ?? Duration.zero;
  Map<String, dynamic>? get currentSong => _playerLogic?.currentSong;
  PlayerLogic? get playerLogic => _playerLogic;
  bool get hasPlayer => _playerLogic != null;
}