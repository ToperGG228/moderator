package com.example.generatedapp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.example.generatedapp.ui.theme.GeneratedAppTheme
import com.example.generatedapp.ui.MainScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            GeneratedAppTheme {
                MainScreen()
            }
        }
    }
}
