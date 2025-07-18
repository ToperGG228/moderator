package com.example.generatedapp.ui

import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.navigation.compose.rememberNavController
import com.example.generatedapp.navigation.AppNavGraph
import com.example.generatedapp.navigation.BottomBar
import com.example.generatedapp.ui.background.ChalkBackground

@Composable
fun MainScreen() {
    val navController = rememberNavController()
    ChalkBackground {
        Scaffold(
            bottomBar = { BottomBar(navController) },
            containerColor = Color.Transparent
        ) { inner ->
            AppNavGraph(navController)
        }
    }
}
