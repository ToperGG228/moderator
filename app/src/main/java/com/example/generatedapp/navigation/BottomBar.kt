package com.example.generatedapp.navigation

import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import androidx.navigation.compose.currentBackStackEntryAsState

@Composable
fun BottomBar(navController: NavController) {
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    NavigationBar(containerColor = Color(0xFF4CAF50)) {
        Screen.items.forEach { screen ->
            val selected = currentRoute == screen.route
            NavigationBarItem(
                selected = selected,
                onClick = { navController.navigate(screen.route) },
                icon = {
                    Icon(
                        imageVector = screen.icon,
                        contentDescription = screen.title,
                        tint = if (selected) Color(0xFFFFEB3B) else Color.White
                    )
                },
                label = {
                    Text(text = screen.title, color = if (selected) Color(0xFFFFEB3B) else Color.White)
                },
                alwaysShowLabel = true,
                colors = androidx.compose.material3.NavigationBarItemDefaults.colors(
                    indicatorColor = Color.Transparent
                )
            )
        }
    }
}
