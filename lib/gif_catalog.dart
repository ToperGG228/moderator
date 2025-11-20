import 'dart:convert';

import 'package:flutter/services.dart';

class GifAssetCatalog {
  GifAssetCatalog(this.items);

  final List<String> items;

  static Future<GifAssetCatalog> load({String prefix = 'assets/gifs/'}) async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = jsonDecode(manifestContent) as Map<String, dynamic>;
    final gifs = manifestMap.keys
        .where((key) => key.startsWith(prefix) && key.toLowerCase().endsWith('.gif'))
        .toList()
      ..sort();
    return GifAssetCatalog(gifs);
  }
}
