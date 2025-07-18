package com.example.generatedapp.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.generatedapp.ui.screens.CardScreen
import com.example.generatedapp.ui.screens.PromosScreen
import com.example.generatedapp.ui.screens.ProfileScreen
import com.example.generatedapp.ui.screens.InfoScreen
import com.example.generatedapp.ui.screens.HelpScreen

@Composable
fun AppNavGraph(navController: NavHostController = rememberNavController()) {
    NavHost(navController = navController, startDestination = Screen.Card.route) {
        composable(Screen.Card.route) { CardScreen() }
        composable(Screen.Promos.route) { PromosScreen() }
        composable(Screen.Profile.route) { ProfileScreen() }
        composable(Screen.Info.route) { InfoScreen() }
        composable(Screen.Help.route) { HelpScreen(navController) }
    }
}
