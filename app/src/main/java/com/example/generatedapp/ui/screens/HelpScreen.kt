package com.example.generatedapp.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.example.generatedapp.navigation.Screen
import com.example.generatedapp.ui.background.ChalkBackground
import com.example.generatedapp.ui.qr.QrHolder
import com.example.generatedapp.ui.qr.generateQrBitmap

@Composable
fun HelpScreen(navController: NavController) {
    var subject by rememberSaveable { mutableStateOf("") }
    var body by rememberSaveable { mutableStateOf("") }
    var bitmap by rememberSaveable { mutableStateOf(QrHolder.bitmap) }
    ChalkBackground {
        Column(modifier = Modifier.padding(16.dp).fillMaxHeight()) {
            OutlinedTextField(value = subject, onValueChange = { subject = it }, label = { Text("Тема") }, singleLine = true)
            OutlinedTextField(value = body, onValueChange = { body = it }, label = { Text("Сообщение") }, modifier = Modifier.weight(1f), maxLines = Int.MAX_VALUE)
            Button(onClick = {
                val text = if (body.isNotBlank()) body else subject
                bitmap = generateQrBitmap(text)
                QrHolder.bitmap = bitmap
                navController.navigate(Screen.Card.route)
            }, colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2E7D32)), modifier = Modifier.fillMaxWidth()) {
                Text("ОТПРАВИТЬ", color = Color.White)
            }
            bitmap?.let {
                Image(bitmap = it.asImageBitmap(), contentDescription = null, modifier = Modifier.padding(top = 16.dp).fillMaxWidth())
            }
        }
    }
}
