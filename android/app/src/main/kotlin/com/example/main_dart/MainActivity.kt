package com.example.main_dart

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    
    companion object {
        init {
            // 🔥 Senior Engineer: Native Silencer for Hardware Spam
            // Setting these tags to ASSERT effectively mutes them in the console
            System.setProperty("log.tag.BufferQueueProducer", "ASSERT")
            System.setProperty("log.tag.BLAST", "ASSERT")
            System.setProperty("log.tag.SurfaceView", "ASSERT")
            System.setProperty("log.tag.SurfaceControl", "ASSERT")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Static block handles the suppression at class load time
    }
}
