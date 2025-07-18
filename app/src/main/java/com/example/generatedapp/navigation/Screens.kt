package com.example.generatedapp.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocalOffer
import androidx.compose.ui.graphics.vector.ImageVector

sealed class Screen(val route: String, val title: String, val icon: ImageVector) {
    object Card : Screen("card", "Карта", Icons.Default.CreditCard)
    object Promos : Screen("promos", "Акции", Icons.Default.LocalOffer)
    object Profile : Screen("profile", "Профиль", Icons.Default.AccountCircle)
    object Info : Screen("info", "Инфо", Icons.Default.Info)
    object Help : Screen("help", "Помощь", Icons.Default.Email)
    companion object {
        val items = listOf(Card, Promos, Profile, Info, Help)
    }
}
