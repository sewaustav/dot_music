package com.example.dot_music

import io.flutter.embedding.android.FlutterFragmentActivity
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity : FlutterFragmentActivity() {
    override fun provideFlutterEngine(context: android.content.Context): io.flutter.embedding.engine.FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }
}