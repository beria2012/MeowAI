import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/theme.dart';
import '../models/cat_breed.dart';
import '../services/database_service.dart';

class BreedDetailScreen extends StatefulWidget {
  final CatBreed breed;

  const BreedDetailScreen({
    super.key,
    required this.breed,
  });

  @override
  State<BreedDetailScreen> createState() => _BreedDetailScreenState();
}

class _BreedDetailScreenState extends State<BreedDetailScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _headerAnimationController;
  late AnimationController _fabAnimationController;
  
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isHeaderExpanded = true;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    
    _scrollController = ScrollController();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scrollController.addListener(_onScroll);
    _headerAnimationController.forward();
    _fabAnimationController.forward();
    
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final shouldExpand = offset < 100;
    
    if (shouldExpand != _isHeaderExpanded) {
      setState(() {
        _isHeaderExpanded = shouldExpand;
      });
      
      if (shouldExpand) {
        _headerAnimationController.forward();
      } else {
        _headerAnimationController.reverse();
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      if (!_databaseService.isInitialized) {
        await _databaseService.initialize();
      }
      
      final favorites = await _databaseService.getFavorites();
      final isFavorite = favorites.any(
        (favorite) => favorite['breed_id'] == widget.breed.id,
      );
      
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      print('❌ BreedDetailScreen: Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;
    
    setState(() {
      _isLoadingFavorite = true;
    });
    
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    
    try {
      if (!_databaseService.isInitialized) {
        await _databaseService.initialize();
      }
      
      bool success;
      if (_isFavorite) {
        // Remove from favorites
        final favorites = await _databaseService.getFavorites();
        final favorite = favorites.firstWhere(
          (f) => f['breed_id'] == widget.breed.id,
          orElse: () => {},
        );
        
        if (favorite.isNotEmpty) {
          success = await _databaseService.removeFavorite(favorite['id'] as String);
        } else {
          success = false;
        }
      } else {
        // Add to favorites
        success = await _databaseService.addToFavorites(
          id: 'breed_${widget.breed.id}_${DateTime.now().millisecondsSinceEpoch}',
          breedId: widget.breed.id,
          note: 'Added from breed details',
        );
      }
      
      if (success && mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isFavorite 
                      ? '${widget.breed.name} added to favorites'
                      : '${widget.breed.name} removed from favorites',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: _isFavorite ? AppTheme.primaryColor : AppTheme.textSecondary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ BreedDetailScreen: Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedBuilder(
          animation: _headerAnimationController,
          builder: (context, child) {
            return Text(
              widget.breed.name,
              style: TextStyle(
                fontSize: 20 + (4 * _headerAnimationController.value),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Breed image with fallback
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildBreedImage(),
                  ),
                ),
              ),
              
              // Breed badges
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    if (widget.breed.isRare)
                      _buildBadge('Rare', AppTheme.errorColor),
                    if (widget.breed.isHypoallergenic) ...[
                      if (widget.breed.isRare) const SizedBox(width: 8),
                      _buildBadge('Hypoallergenic', AppTheme.secondaryColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBreedImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Try to load actual breed image first
        Image.asset(
          widget.breed.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient placeholder when image not found
            return _buildImagePlaceholder();
          },
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    final gradientColors = _getBreedGradientColors(widget.breed.name.hashCode);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Subtle paw pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: PawPatternPainter(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Center icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets,
                size: 48,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          // Breed name overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Text(
                widget.breed.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }






  
  List<Color> _getBreedGradientColors(int hash) {
    // Create unique but pleasing gradients for each breed
    final gradients = [
      [AppTheme.primaryColor, AppTheme.accentColor],
      [AppTheme.secondaryColor, const Color(0xFF4CAF50)],
      [AppTheme.primaryColor, AppTheme.secondaryColor],
      [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
      [const Color(0xFF2196F3), const Color(0xFF03DAC6)],
      [const Color(0xFFFF5722), const Color(0xFFFF9800)],
      [const Color(0xFF795548), const Color(0xFF8D6E63)],
      [const Color(0xFF607D8B), const Color(0xFF90A4AE)],
    ];
    
    final index = hash.abs() % gradients.length;
    return gradients[index];
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single card with breed photo and description
          _buildBreedCard().animate().fadeIn(delay: 100.ms, duration: 600.ms),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildBreedCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full description section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick info row
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickInfo('Lifespan', widget.breed.lifeSpan, Icons.schedule),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickInfo('Weight', widget.breed.weight, Icons.fitness_center),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Temperament
                Text(
                  'Temperament',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.breed.temperament,
                  style: AppTextStyles.bodyLarge.copyWith(
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Full Description
                Text(
                  'About ${widget.breed.name}',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.breed.description,
                  style: AppTextStyles.bodyLarge.copyWith(
                    height: 1.6,
                    color: AppTheme.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // History
                Text(
                  'History & Background',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.breed.history,
                  style: AppTextStyles.bodyLarge.copyWith(
                    height: 1.6,
                    color: AppTheme.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Characteristics chips
                if (widget.breed.characteristics.isNotEmpty) ...[
                  Text(
                    'Key Characteristics',
                    style: AppTextStyles.headline3.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.breed.characteristics.map((characteristic) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          characteristic,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Trait levels
                Text(
                  'Care Requirements',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildSimpleTraitBar('Energy Level', widget.breed.energyLevel, AppTheme.primaryColor),
                const SizedBox(height: 12),
                _buildSimpleTraitBar('Grooming Needs', widget.breed.groomingNeeds, AppTheme.accentColor),
                const SizedBox(height: 12),
                _buildSimpleTraitBar('Social Needs', widget.breed.socialNeeds, AppTheme.secondaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildQuickInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTraitBar(String label, int value, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value / 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$value/5',
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_fabAnimationController.value * 0.1),
          child: FloatingActionButton(
            onPressed: _isLoadingFavorite ? null : _toggleFavorite,
            backgroundColor: _isFavorite ? AppTheme.errorColor : AppTheme.primaryColor,
            child: _isLoadingFavorite
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
          ),
        );
      },
    );
  }
}

class PawPatternPainter extends CustomPainter {
  final Color color;
  
  PawPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final pawSize = 20.0;
    final spacing = pawSize * 3;
    
    // Draw paw prints in a pattern
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawPaw(canvas, paint, Offset(x, y), pawSize * 0.6);
      }
    }
    
    // Draw offset paws for more interesting pattern
    for (double x = spacing / 2; x < size.width + spacing; x += spacing) {
      for (double y = spacing / 2; y < size.height + spacing; y += spacing) {
        _drawPaw(canvas, paint, Offset(x, y), pawSize * 0.4);
      }
    }
  }
  
  void _drawPaw(Canvas canvas, Paint paint, Offset center, double size) {
    // Main pad
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size * 1.2,
      ),
      paint,
    );
    
    // Toes
    final toeSize = size * 0.3;
    final toeOffset = size * 0.4;
    
    // Top toes
    canvas.drawCircle(
      center + Offset(-toeOffset * 0.8, -toeOffset),
      toeSize,
      paint,
    );
    
    canvas.drawCircle(
      center + Offset(0, -toeOffset * 1.2),
      toeSize,
      paint,
    );
    
    canvas.drawCircle(
      center + Offset(toeOffset * 0.8, -toeOffset),
      toeSize,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}