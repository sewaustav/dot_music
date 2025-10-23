import 'package:dot_music/features/pages/player/player_holder.dart';
import 'package:dot_music/features/pages/player/service.dart';
import 'package:dot_music/features/pages/player/ui.dart';
import 'package:flutter/material.dart';
import 'package:dot_music/design/colors.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key, 
    required this.path, 
    required this.playlist, 
    required this.index,
  });

  final String path;
  final int playlist;
  final int index;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late PlayerLogic _logic;
  bool isPlaying = true;
  bool isLoadingPlaybackCount = true;

  @override
  void initState() {
    super.initState();
    _refreshUI();
    _logic = PlayerLogic(
      refreshUI: _refreshUI,
      initialIndex: widget.index,
      playlist: widget.playlist,
      refreshBtn: refreshBtn,
      onPlaybackCountLoaded: _onPlaybackCountLoaded,
    );
    playerLogicHolder.set(_logic);
    _logic.init();
  }

  void _refreshUI() {
    if (mounted) {
      setState(() {});
    }
  }

  void refreshBtn(bool cond) {
    setState(() {
      isPlaying = cond;
    });
  }

  void _onPlaybackCountLoaded(bool loading) {
    if (mounted) {
      setState(() {
        isLoadingPlaybackCount = loading;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        title: Text(_logic.currentTitle),
        actions: [
          IconButton(
            onPressed: _openPlayerSettings,
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    PlayerHeader(
                      title: _logic.currentTitle,
                      artist: _logic.currentArtist,
                      playbackCount: _logic.playbackCount,
                      isLoading: isLoadingPlaybackCount,
                    ),

                    const SizedBox(height: 24),

                    if (_logic.totalDuration.inMilliseconds > 0) ...[
                      PlayerProgress(
                        current: _logic.currentPosition,
                        total: _logic.totalDuration,
                        onSeek: _logic.seek,
                      ),
                      const SizedBox(height: 12),
                    ],

                    PlayerControls(
                      isPlaying: isPlaying,
                      repeatMode: _logic.repeatMode,
                      onPlayPause: _logic.togglePlayPause,
                      onNext: _logic.playNextSong,
                      onPrev: _logic.playPreviousSong,
                      onShuffle: _logic.playRandomSong,
                      onChangeRepeatMode: _logic.changeRepeatMode,
                    ),

                    const SizedBox(height: 40),

                    PlayerActionsRow(
                      onOpenPlaylist: _openPlaylistView,
                      onFavorite: _addToFavorites,
                      onDelete: _removeFromPlaylist,
                      onEdit: _editTrackInfo,
                    ),
                  ],
                ),
              ),

              if (_logic.error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)),
                  child: Text(_logic.error!, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 12),
              ]
            ],
          ),
        ),
      ),
    );
  }

  void _openPlaylistView() {}
  void _addToFavorites() {}
  void _removeFromPlaylist() {}
  void _editTrackInfo() {}
  void _openPlayerSettings() {}
}