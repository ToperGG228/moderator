package com.example.generatedapp.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.generatedapp.ui.background.ChalkBackground

@Composable
fun InfoScreen() {
    val paragraphs = listOf(
        "Это пример приложения.",
        "Оно демонстрирует работу QR-кодов и навигации.",
        "Используйте его как основу для своих проектов."
    )
    val getCard = listOf("Зайдите в магазин", "Заполните анкету", "Получите карту")
    val activate = listOf("Откройте приложение", "Нажмите активировать", "Следуйте инструкциям")
    ChalkBackground {
        LazyColumn(modifier = Modifier.padding(16.dp)) {
            item { Text(text = "О программе", color = Color.White, fontSize = 20.sp) }
            items(paragraphs.size) { i -> Text(text = paragraphs[i], color = Color.White, lineHeight = 20.sp) }
            item { Text(text = "Получение карты:", color = Color.White, modifier = Modifier.padding(top = 8.dp)) }
            items(getCard.size) { i -> Text(text = "${i+1}. ${getCard[i]}", color = Color.White, lineHeight = 20.sp) }
            item { Text(text = "Активация:", color = Color.White, modifier = Modifier.padding(top = 8.dp)) }
            items(activate.size) { i -> Text(text = "${i+1}. ${activate[i]}", color = Color.White, lineHeight = 20.sp) }
        }
    }
}
