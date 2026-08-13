import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/wallpaper.dart';
import '../services/ad_service.dart';
import '../services/wallpaper_service.dart';
import 'wallpaper_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Wallpaper> _wallpapers = [];
  List<Wallpaper> _filteredWallpapers = [];
  List<String> _favoriteIds = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  // Banner Ad
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final List<String> _categories = [
    'All',
    'Cyberpunk',
    'Samurai',
    'Aesthetic',
    'Fantasy',
    'Monochrome',
    'Villains',
  ];

  @override
  void initState() {
    super.initState();
    _loadWallpapers();
    _initBannerAd();
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner Ad failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadWallpapers() async {
    setState(() => _isLoading = true);
    final wallpapers = await WallpaperService.instance.fetchWallpapers();
    final favIds = await WallpaperService.instance.getFavoriteIds();
    setState(() {
      _wallpapers = wallpapers;
      _favoriteIds = favIds;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    List<Wallpaper> list = List.from(_wallpapers);

    if (_showFavoritesOnly) {
      list = list.where((w) => _favoriteIds.contains(w.id)).toList();
    } else if (_selectedCategory != 'All') {
      list = list
          .where((w) =>
              w.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list
          .where((w) =>
              w.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              w.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    _filteredWallpapers = list;
  }

  void _onCategorySelected(String cat) {
    setState(() {
      _selectedCategory = cat;
      _showFavoritesOnly = false;
      _applyFilters();
    });
  }

  void _toggleFavoritesView() async {
    final favIds = await WallpaperService.instance.getFavoriteIds();
    setState(() {
      _favoriteIds = favIds;
      _showFavoritesOnly = !_showFavoritesOnly;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFBB86FC).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dark_mode_rounded,
                  color: Color(0xFFBB86FC), size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'DARK ANIME',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _showFavoritesOnly ? Colors.redAccent : Colors.white70,
            ),
            tooltip: 'Saved Favorites',
            onPressed: _toggleFavoritesView,
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white70),
            tooltip: 'Search',
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories list
          if (!_showFavoritesOnly) _buildCategoriesRow(),

          if (_showFavoritesOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF161616),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Favorite Wallpapers',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: _toggleFavoritesView,
                    child: const Text(
                      'Show All',
                      style: TextStyle(
                          color: Color(0xFFBB86FC),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Wallpapers Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFBB86FC)))
                : _filteredWallpapers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadWallpapers,
                        color: const Color(0xFFBB86FC),
                        backgroundColor: const Color(0xFF1E1E1E),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: _filteredWallpapers.length,
                          itemBuilder: (context, index) {
                            return _buildWallpaperCard(
                                _filteredWallpapers[index]);
                          },
                        ),
                      ),
          ),

          // Google AdMob Banner Ad at Bottom
          if (_isBannerAdLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              color: Colors.black,
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFFBB86FC),
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFBB86FC) : Colors.transparent,
                ),
              ),
              showCheckmark: false,
              onSelected: (_) => _onCategorySelected(cat),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWallpaperCard(Wallpaper wallpaper) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => WallpaperDetailScreen(wallpaper: wallpaper),
          ),
        );
        // Refresh favorite state when returning
        final favIds = await WallpaperService.instance.getFavoriteIds();
        setState(() {
          _favoriteIds = favIds;
          if (_showFavoritesOnly) _applyFilters();
        });
      },
      child: Hero(
        tag: wallpaper.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: wallpaper.thumbnailUrl ?? wallpaper.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF1A1A1A),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF1A1A1A),
                  child: const Icon(Icons.broken_image, color: Colors.white24),
                ),
              ),
              // Subtle gradient overlay for readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xCC000000),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        wallpaper.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wallpaper.category,
                        style: const TextStyle(
                          color: Color(0xFFBB86FC),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.filter_none_rounded, size: 60, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            _showFavoritesOnly
                ? 'No favorites yet!\nTap the heart icon on any wallpaper.'
                : 'No wallpapers found.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: _searchQuery);
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Search Wallpapers',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Samurai, Cyberpunk, Dragon...',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFBB86FC)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _applyFilters();
                });
                Navigator.pop(ctx);
              },
              child:
                  const Text('Clear', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB86FC),
              ),
              onPressed: () {
                setState(() {
                  _searchQuery = controller.text.trim();
                  _applyFilters();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Search',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
