import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallpaper.dart';

class WallpaperService {
  static final WallpaperService instance = WallpaperService._internal();
  WallpaperService._internal();

  // You can host your JSON on GitHub raw, Supabase, Firebase, or Cloudinary.
  // We provide high-quality fallback wallpapers so the app works out-of-the-box!
  static const String remoteJsonUrl =
      'https://raw.githubusercontent.com/username/dark-anime-wallpapers/main/wallpapers.json';

  static const String _favoritesKey = 'favorite_wallpapers_v1';

  final List<Wallpaper> _fallbackWallpapers = [
    Wallpaper(
      id: '1',
      title: 'Neon Cyber Shinobi',
      category: 'Cyberpunk',
      url: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?q=80&w=1080',
      author: 'Aesthetic Studios',
    ),
    Wallpaper(
      id: '2',
      title: 'Shadow Samurai Eclipse',
      category: 'Samurai',
      url: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?q=80&w=1080',
      author: 'Kage Art',
    ),
    Wallpaper(
      id: '3',
      title: 'Midnight Tokyo Rain',
      category: 'Aesthetic',
      url: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?q=80&w=1080',
      author: 'Neon Dreams',
    ),
    Wallpaper(
      id: '4',
      title: 'Dark Dragon Slayer',
      category: 'Fantasy',
      url: 'https://images.unsplash.com/photo-1563089145-599997674d42?q=80&w=1080',
      author: 'Mythic Core',
    ),
    Wallpaper(
      id: '5',
      title: 'Monochrome Katana Ghost',
      category: 'Monochrome',
      url: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=1080',
      author: 'Sumi Shadows',
    ),
    Wallpaper(
      id: '6',
      title: 'Crimson Hollow Blade',
      category: 'Villains',
      url: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=1080',
      author: 'Abyss Art',
    ),
  ];

  Future<List<Wallpaper>> fetchWallpapers() async {
    try {
      final response = await http
          .get(Uri.parse(remoteJsonUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Wallpaper.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Remote fetch fallback: Using offline starter pack ($e)');
    }
    return _fallbackWallpapers;
  }

  Future<List<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<bool> isFavorite(String id) async {
    final favs = await getFavoriteIds();
    return favs.contains(id);
  }

  Future<void> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_favoritesKey) ?? [];
    if (favs.contains(id)) {
      favs.remove(id);
    } else {
      favs.add(id);
    }
    await prefs.setStringList(_favoritesKey, favs);
  }
}
