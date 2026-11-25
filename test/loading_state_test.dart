import 'package:dot_music/features/track_service/load_tracks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('рассылка слушателям переживает отписку во время notify', () {
    late VoidCallback selfRemoving;
    var calls = 0;

    selfRemoving = () {
      calls++;
      TrackLoadingState.listeners.remove(selfRemoving);
    };
    TrackLoadingState.listeners.add(selfRemoving);
    TrackLoadingState.listeners.add(() => calls++);

    expect(TrackLoadingState.notify, returnsNormally);
    expect(calls, 2);
    expect(TrackLoadingState.listeners, hasLength(1));

    TrackLoadingState.listeners.removeWhere((l) => l != selfRemoving);
    TrackLoadingState.listeners.clear();
  });
}
