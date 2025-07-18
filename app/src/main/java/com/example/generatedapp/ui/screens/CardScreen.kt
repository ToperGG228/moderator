package com.example.generatedapp.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.unit.dp
import com.example.generatedapp.ui.background.ChalkBackground
import com.example.generatedapp.ui.qr.QrHolder

@Composable
fun CardScreen() {
    val bitmap = QrHolder.bitmap
    ChalkBackground {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            if (bitmap != null) {
                Image(bitmap = bitmap.asImageBitmap(), contentDescription = null, modifier = Modifier.size(260.dp))
            } else {
                Text(text = "QR ещё не сгенерирован", color = androidx.compose.ui.graphics.Color.White)
            }
        }
    }
}
