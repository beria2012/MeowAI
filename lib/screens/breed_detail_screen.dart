import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/theme.dart';
import '../models/cat_breed.dart';
import '../widgets/cat_paw_button.dart';

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
  
  bool _isHeaderExpanded = true;
  bool _isFavorite = false;

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

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    
    // Here you would typically save to database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite 
              ? '${widget.breed.name} added to favorites'
              : '${widget.breed.name} removed from favorites',
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
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
              
              // Breed image placeholder
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(top: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 60,
                    color: Colors.white,
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

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfo().animate().fadeIn(delay: 200.ms, duration: 600.ms),
          const SizedBox(height: 24),
          _buildCharacteristics().animate().fadeIn(delay: 400.ms, duration: 600.ms),
          const SizedBox(height: 24),
          _buildDescription().animate().fadeIn(delay: 600.ms, duration: 600.ms),
          const SizedBox(height: 24),
          _buildHistory().animate().fadeIn(delay: 800.ms, duration: 600.ms),
          const SizedBox(height: 24),
          _buildTraitBars().animate().fadeIn(delay: 1000.ms, duration: 600.ms),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: AppTextStyles.headline2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Origin', widget.breed.origin, Icons.public),
            const SizedBox(height: 12),
            _buildInfoRow('Life Span', widget.breed.lifeSpan, Icons.schedule),
            const SizedBox(height: 12),
            _buildInfoRow('Weight', widget.breed.weight, Icons.fitness_center),
            const SizedBox(height: 12),
            _buildInfoRow('Temperament', widget.breed.temperament, Icons.mood),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCharacteristics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Characteristics',
              style: AppTextStyles.headline2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.breed.characteristics.map((characteristic) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    characteristic,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: AppTextStyles.headline2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              widget.breed.description,
              style: AppTextStyles.bodyLarge.copyWith(
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_edu,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'History & Origin',
                  style: AppTextStyles.headline2.copyWith(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.breed.history,
              style: AppTextStyles.bodyLarge.copyWith(
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraitBars() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Traits',
              style: AppTextStyles.headline2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 20),
            
            _buildTraitBar('Energy Level', widget.breed.energyLevel, AppTheme.primaryColor),
            const SizedBox(height: 16),
            _buildTraitBar('Shedding Level', widget.breed.sheddingLevel, AppTheme.errorColor),
            const SizedBox(height: 16),
            _buildTraitBar('Social Needs', widget.breed.socialNeeds, AppTheme.secondaryColor),
            const SizedBox(height: 16),
            _buildTraitBar('Grooming Needs', widget.breed.groomingNeeds, AppTheme.accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTraitBar(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value/5',
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 5,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ).animate().scaleX(
          duration: 800.ms,
          curve: Curves.easeOut,
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
            onPressed: _toggleFavorite,
            backgroundColor: _isFavorite ? AppTheme.errorColor : AppTheme.primaryColor,
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}