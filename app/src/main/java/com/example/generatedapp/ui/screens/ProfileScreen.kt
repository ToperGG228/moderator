package com.example.generatedapp.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Switch
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.example.generatedapp.ui.background.ChalkBackground
import kotlinx.coroutines.launch

@Composable
fun ProfileScreen() {
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("Профиль", "Покупки", "Сообщения")
    ChalkBackground {
        Column {
            TabRow(selectedTabIndex = selectedTab) {
                tabs.forEachIndexed { index, title ->
                    Tab(selected = selectedTab == index, onClick = { selectedTab = index }) {
                        Text(text = title, color = Color.White, modifier = Modifier.padding(16.dp))
                    }
                }
            }
            when (selectedTab) {
                0 -> ProfileTabContent()
                else -> Text(text = "Заглушка", color = Color.White, modifier = Modifier.padding(16.dp))
            }
        }
    }
}

@Composable
fun ProfileTabContent() {
    var switchState by remember { mutableStateOf(false) }
    val scroll = rememberScrollState()
    Column(modifier = Modifier.verticalScroll(scroll).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        listOf(
            "Имя: Иван",
            "Фамилия: Иванов",
            "Дата: 01.01.2000",
            "Пол: мужской",
            "Телефон: +79990000000",
            "Email: ivan@example.com",
            "Город: Москва"
        ).forEach { Text(text = it, color = Color.White) }
        Text(text = "Введите номер пластиковой карты", color = Color(0xFFFFEB3B))
        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
            Text(text = "Электронные чеки", color = Color.White)
            Spacer(modifier = Modifier.weight(1f))
            Switch(checked = switchState, onCheckedChange = { switchState = it })
        }
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = {}, modifier = Modifier.weight(1f), colors = androidx.compose.material3.ButtonDefaults.buttonColors(containerColor = Color(0xFF2E7D32))) {
                Text("СОХРАНИТЬ", color = Color.White)
            }
            Button(onClick = {}, modifier = Modifier.weight(1f), colors = androidx.compose.material3.ButtonDefaults.buttonColors(containerColor = Color(0xFF2E7D32))) {
                Text("СМЕНИТЬ ПАРОЛЬ", color = Color.White)
            }
        }
    }
}
