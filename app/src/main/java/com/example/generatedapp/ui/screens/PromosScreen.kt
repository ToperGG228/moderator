package com.example.generatedapp.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.example.generatedapp.R
import com.example.generatedapp.ui.background.ChalkBackground

@Composable
fun PromosScreen() {
    val promos = listOf(1, 2)
    ChalkBackground {
        LazyColumn(modifier = Modifier.padding(16.dp), verticalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(20.dp)) {
            items(promos) {
                Row(modifier = Modifier.fillMaxWidth()) {
                    Image(
                        painter = painterResource(R.drawable.bg_chalk),
                        contentDescription = null,
                        modifier = Modifier.size(110.dp),
                        contentScale = ContentScale.Crop
                    )
                    Spacer(modifier = Modifier.size(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = "Заголовок акции", color = Color(0xFF1B5E20))
                        Text(text = "Описание акции", color = Color.White)
                    }
                }
            }
            item {
                Column {
                    Text(text = "Важно", color = Color(0xFF1B5E20))
                    Text(text = "Информация об акции", color = Color.White)
                }
            }
        }
    }
}
