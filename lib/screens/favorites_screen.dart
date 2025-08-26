import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/database_service.dart';
import '../services/breed_data_service.dart';
import '../utils/theme.dart';
import '../models/cat_breed.dart';
import '../widgets/cat_paw_button.dart';
import 'breed_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final BreedDataService _breedDataService = BreedDataService();
  
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('💖 FavoritesScreen: Loading favorites...');
      
      if (!_databaseService.isInitialized) {
        await _databaseService.initialize();
      }
      
      final favorites = await _databaseService.getFavorites();
      print('💖 FavoritesScreen: Loaded ${favorites.length} favorites');
      
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ FavoritesScreen: Error loading favorites: $e');
      setState(() {
        _errorMessage = 'Failed to load favorites: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String id) async {
    try {
      final success = await _databaseService.removeFavorite(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        await _loadFavorites(); // Refresh the list
      } else {
        throw Exception('Failed to remove favorite');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing favorite: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.favorite,
              color: AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'My Favorites',
              style: AppTextStyles.headline2.copyWith(
                color: AppTheme.primaryColor,
                fontSize: 24,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.pets),
              text: 'Breeds (${_getBreedFavorites().length})',
            ),
            Tab(
              icon: const Icon(Icons.photo),
              text: 'Photos (${_getPhotoFavorites().length})',
            ),
          ],
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
        ),
      ),
      body: _isLoading ? _buildLoadingView() : _buildContent(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingPawAnimation(
            message: 'Loading favorites...',
            size: 60,
          ),
          SizedBox(height: 16),
          Text(
            'Gathering your saved breeds and photos...',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    if (_favorites.isEmpty) {
      return _buildEmptyView();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildBreedsTab(),
        _buildPhotosTab(),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: AppTextStyles.headline3,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFavorites,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.white,
            ),
          )
              .animate()
              .scale(delay: 200.ms, duration: 600.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          Text(
            'No Favorites Yet',
            style: AppTextStyles.headline2,
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring cat breeds and save your favorites!\nTap the heart icon on breed details to add them here.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.explore),
            label: const Text('Explore Breeds'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreedsTab() {
    final breedFavorites = _getBreedFavorites();
    
    if (breedFavorites.isEmpty) {
      return _buildEmptyTabView(
        icon: Icons.pets,
        title: 'No Favorite Breeds',
        description: 'Explore the encyclopedia and add breeds to your favorites!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: breedFavorites.length,
        itemBuilder: (context, index) {
          final favorite = breedFavorites[index];
          return _buildBreedFavoriteCard(favorite, index);
        },
      ),
    );
  }

  Widget _buildPhotosTab() {
    final photoFavorites = _getPhotoFavorites();
    
    if (photoFavorites.isEmpty) {
      return _buildEmptyTabView(
        icon: Icons.photo,
        title: 'No Favorite Photos',
        description: 'Take photos and save your recognition results to see them here!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: photoFavorites.length,
        itemBuilder: (context, index) {
          final favorite = photoFavorites[index];
          return _buildPhotoFavoriteCard(favorite, index);
        },
      ),
    );
  }

  Widget _buildEmptyTabView({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.headline3.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreedFavoriteCard(Map<String, dynamic> favorite, int index) {
    final breedId = favorite['breed_id'] as String?;
    final note = favorite['note'] as String?;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      favorite['created_at'] as int,
    );

    if (breedId == null) {
      return const SizedBox.shrink();
    }

    final breed = _breedDataService.getBreedById(breedId);
    if (breed == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BreedDetailScreen(breed: breed),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Breed icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              // Breed info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      breed.name,
                      style: AppTextStyles.headline3.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      breed.origin,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        note,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Added ${_formatDate(createdAt)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      _removeFavorite(favorite['id'] as String);
                    },
                    icon: const Icon(
                      Icons.favorite,
                      color: AppTheme.errorColor,
                    ),
                    tooltip: 'Remove from favorites',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BreedDetailScreen(breed: breed),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                    ),
                    tooltip: 'View details',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 100)).slideX().fadeIn();
  }

  Widget _buildPhotoFavoriteCard(Map<String, dynamic> favorite, int index) {
    final imagePath = favorite['image_path'] as String?;
    final recognitionId = favorite['recognition_id'] as String?;
    final note = favorite['note'] as String?;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      favorite['created_at'] as int,
    );

    if (imagePath == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient.scale(0.1),
                ),
                child: File(imagePath).existsSync()
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
          ),
          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recognitionId != null) ...[
                    Text(
                      'Recognition Result',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (note != null && note.isNotEmpty) ...[
                    Text(
                      note,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    _formatDate(createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: () {
                            _removeFavorite(favorite['id'] as String);
                          },
                          icon: const Icon(
                            Icons.favorite,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                          tooltip: 'Remove',
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          onPressed: () {
                            // TODO: Implement full-screen image view
                            _showImageDialog(imagePath);
                          },
                          icon: const Icon(
                            Icons.fullscreen,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          tooltip: 'View',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 100)).scale().fadeIn();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo,
            size: 32,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'Image not found',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              // Image
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  child: File(imagePath).existsSync()
                      ? Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                        )
                      : _buildImagePlaceholder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getBreedFavorites() {
    return _favorites
        .where((favorite) => favorite['breed_id'] != null)
        .toList();
  }

  List<Map<String, dynamic>> _getPhotoFavorites() {
    return _favorites
        .where((favorite) => favorite['image_path'] != null)
        .toList();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}