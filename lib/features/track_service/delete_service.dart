import 'package:dot_music/core/db/block_service.dart';

class DeleteService {
  final bs = BlockService();

  Future<void> addToBlackList(int trackId) async {
    await bs.blockTrack(trackId);
  }

  Future<void> deleteFromBlackList(int trackId) async {
    await bs.unblockTrack(trackId);
  }

  Future<bool> isBlocked(int trackId) async {
    return await bs.isBlocked(trackId);
  }

}