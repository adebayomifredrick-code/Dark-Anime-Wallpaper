import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gal/gal.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../models/wallpaper.dart';
import '../services/ad_service.dart';
import '../services/wallpaper_service.dart';

class WallpaperDetailScreen extends StatefulWidget {
  final Wallpaper wallpaper;

  const WallpaperDetailScreen({super.key, required this.wallpaper});

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  bool _isFavorite = false;
  bool _isActionInProgress = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final fav = await WallpaperService.instance.isFavorite(widget.wallpaper.id);
    if (mounted) {
      setState(() => _isFavorite = fav);
    }
  }

  Future<void> _toggleFavorite() async {
    await WallpaperService.instance.toggleFavorite(widget.wallpaper.id);
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Text(
          _isFavorite ? 'Added to Favorites' : 'Removed from Favorites',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    setState(() {
      _isActionInProgress = true;
      _statusMessage = 'Downloading image...';
    });

    try {
      // 1. Download image bytes
      final response = await http.get(Uri.parse(widget.wallpaper.url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image from server');
      }

      // 2. Save directly using Gal (Modern MediaStore API, compliant with Android 10-14+)
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/dark_anime_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Save to device photo gallery
      await Gal.putImage(tempFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00E676),
            content: Text(
              'Successfully saved to your Gallery!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      // Show interstitial ad after successful save
      AdService.instance.showInterstitialAd();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Error saving: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
          _statusMessage = '';
        });
      }
    }
  }

  void _showSetWallpaperDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Set As Wallpaper',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildWallpaperOptionTile(
                icon: Icons.home_rounded,
                title: 'Home Screen',
                target: AsyncWallpaper.HOME_SCREEN,
              ),
              _buildWallpaperOptionTile(
                icon: Icons.lock_outline_rounded,
                title: 'Lock Screen',
                target: AsyncWallpaper.LOCK_SCREEN,
              ),
              _buildWallpaperOptionTile(
                icon: Icons.smartphone_rounded,
                title: 'Both Screens',
                target: AsyncWallpaper.BOTH_SCREENS,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWallpaperOptionTile({
    required IconData icon,
    required String title,
    required int target,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFBB86FC)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
      onTap: () {
        Navigator.pop(context);
        _applyWallpaper(target);
      },
    );
  }

  Future<void> _applyWallpaper(int wallpaperLocation) async {
    setState(() {
      _isActionInProgress = true;
      _statusMessage = 'Setting wallpaper...';
    });

    try {
      final result = await AsyncWallpaper.setWallpaper(
        url: widget.wallpaper.url,
        wallpaperLocation: wallpaperLocation,
        goToHome: false,
        toastDetails: ToastDetails.success(),
        errorToastDetails: ToastDetails.error(),
      );

      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00E676),
            content: Text(
              'Wallpaper applied successfully!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      // Show interstitial ad after setting wallpaper
      AdService.instance.showInterstitialAd();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Could not set wallpaper: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
          _statusMessage = '';
        });
      }
    }
  }

  void _shareWallpaper() {
    Share.share(
      'Check out this epic dark anime wallpaper: ${widget.wallpaper.title}\n${widget.wallpaper.url}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Pinch to Zoom Interactive Image Viewer
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 3.5,
              child: CachedNetworkImage(
                imageUrl: widget.wallpaper.url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFBB86FC),
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.white38),
                ),
              ),
            ),
          ),

          // Top Navigation Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      _buildGlassIconButton(
                        icon: _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: _isFavorite ? Colors.redAccent : Colors.white,
                        onPressed: _toggleFavorite,
                      ),
                      const SizedBox(width: 8),
                      _buildGlassIconButton(
                        icon: Icons.share_rounded,
                        onPressed: _shareWallpaper,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xDD121212),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Save to Gallery Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isActionInProgress ? null : _saveToGallery,
                        icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                        label: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF262626),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Set Wallpaper Button (Main Action)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isActionInProgress ? null : _showSetWallpaperDialog,
                        icon: const Icon(Icons.wallpaper_rounded, color: Colors.black),
                        label: const Text(
                          'Set Wallpaper',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBB86FC),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay if operation is in progress
          if (_isActionInProgress)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFBB86FC)),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x991C1C1E),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
