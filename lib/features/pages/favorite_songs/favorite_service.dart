/* import 'package:dot_music/core/config.dart';
import 'package:dot_music/core/db/fav_service.dart';
import 'package:flutter/material.dart';

class FavoriteLogic extends StatefulWidget {

  const FavoriteLogic();

  @override
  State<StatefulWidget> createState() => FavoriteLogicState();
}

class FavoriteLogicState extends State<FavoriteLogic> {

  Future<bool> checkFavorite(int trackId) async {
    logger.i(trackId);
    final serv = FavoriteService();
    final fav = await serv.isFavorite(trackId);
    return fav;
  }

  Future<void> toggleFavorite(bool isFavorite, int trackId) async {
    logger.i(trackId);
    bool _isFavorite = await checkFavorite(trackId);
    final serv = FavoriteService();
    if (_isFavorite) {
      await serv.deleteFromFav(trackId);
    } else {
      await serv.addTrackToFav(trackId);
    }
    setState(() {
      isFavorite = !_isFavorite;
    });
  }

  
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
} */