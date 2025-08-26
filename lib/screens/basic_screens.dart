import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/theme.dart';
import '../widgets/cat_paw_button.dart';
import '../models/cat_breed.dart';
import '../models/recognition_result.dart';
import '../services/ml_service.dart';
import '../services/breed_data_service.dart';
import '../services/stats_service.dart';
import '../services/database_service.dart';
import 'ar_screen.dart';
import 'breed_detail_screen.dart';

class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BreedDataService _breedService = BreedDataService();
  List<CatBreed> _allBreeds = [];
  List<CatBreed> _filteredBreeds = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBreeds();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBreeds() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final success = await _breedService.initialize();
      if (success) {
        final breeds = _breedService.getAllBreeds();
        setState(() {
          _allBreeds = breeds;
          _filteredBreeds = breeds;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load breed data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading breeds: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _filterBreeds();
  }

  void _filterBreeds() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredBreeds = _allBreeds.where((breed) {
        final matchesSearch = query.isEmpty || 
            breed.name.toLowerCase().contains(query) ||
            breed.origin.toLowerCase().contains(query) ||
            breed.temperament.toLowerCase().contains(query);
        
        final matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'Hypoallergenic' && breed.isHypoallergenic) ||
            (_selectedFilter == 'Rare' && breed.isRare) ||
            (_selectedFilter == 'Popular' && !breed.isRare);
        
        return matchesSearch && matchesFilter;
      }).toList();
      
      // Sort alphabetically
      _filteredBreeds.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterBreeds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Cat Encyclopedia',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _filteredBreeds.isEmpty
                        ? _buildEmptyState()
                        : _buildBreedsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search breeds...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Popular'),
                _buildFilterChip('Rare'),
                _buildFilterChip('Hypoallergenic'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) _setFilter(filter);
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryColor,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'Loading cat breeds...',
            style: AppTextStyles.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
          const Text(
            'Failed to load breeds',
            style: AppTextStyles.headline3,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBreeds,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No breeds found',
            style: AppTextStyles.headline3,
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBreedsList() {
    return Column(
      children: [
        // Results count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade100,
          child: Text(
            '${_filteredBreeds.length} breed${_filteredBreeds.length != 1 ? 's' : ''} found',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        
        // Breeds grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredBreeds.length,
            itemBuilder: (context, index) {
              return _buildBreedCard(_filteredBreeds[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBreedCard(CatBreed breed) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BreedDetailScreen(breed: breed),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breed image with real photo attempt and fallback
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildBreedCardImage(breed),
              ),
            ),
            
            // Breed info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      breed.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      breed.origin,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Energy level indicator
                    Row(
                      children: [
                        const Icon(
                          Icons.flash_on,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: breed.energyLevel / 5,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
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
      ),
    );
  }

  Widget _buildBreedCardImage(CatBreed breed) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Try to load actual breed image first
        Image.asset(
          breed.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient placeholder when image not found
            return _buildBreedCardPlaceholder(breed);
          },
        ),
        // Badges overlay
        Positioned(
          top: 8,
          right: 8,
          child: Column(
            children: [
              if (breed.isRare)
                _buildSmallBadge('Rare', AppTheme.errorColor),
              if (breed.isHypoallergenic) ...[
                if (breed.isRare) const SizedBox(height: 4),
                _buildSmallBadge('Hypo', AppTheme.secondaryColor),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreedCardPlaceholder(CatBreed breed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getBreedCardGradient(breed.name.hashCode),
        ),
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: MiniPawPatternPainter(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          
          // Center icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.pets,
                size: 32,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.info,
              color: AppTheme.primaryColor,
            ),
            SizedBox(width: 8),
            Text('Cat Encyclopedia'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This encyclopedia contains information about ${_allBreeds.length} cat breeds that MeowAI can recognize.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Features:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '• Search by breed name, origin, or temperament\n'
              '• Filter by characteristics\n'
              '• Detailed breed information\n'
              '• Energy level indicators\n'
              '• Hypoallergenic and rare breed badges',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
  
  List<Color> _getBreedCardGradient(int hash) {
    // Create unique but pleasing gradients for each breed (same as detail screen)
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
}

/// Mini paw pattern painter for encyclopedia cards
class MiniPawPatternPainter extends CustomPainter {
  final Color color;
  
  MiniPawPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final pawSize = 12.0;
    final spacing = pawSize * 4;
    
    // Draw fewer, smaller paw prints for cards
    for (double x = spacing / 2; x < size.width + spacing; x += spacing) {
      for (double y = spacing / 2; y < size.height + spacing; y += spacing) {
        _drawMiniPaw(canvas, paint, Offset(x, y), pawSize * 0.5);
      }
    }
  }
  
  void _drawMiniPaw(Canvas canvas, Paint paint, Offset center, double size) {
    // Simplified paw for cards
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size,
        height: size * 1.1,
      ),
      paint,
    );
    
    // Single toe
    canvas.drawCircle(
      center + Offset(0, -size * 0.6),
      size * 0.25,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final BreedDataService _breedService = BreedDataService();
  
  List<RecognitionResult> _recognitionHistory = [];
  bool _isLoading = true;
  String? _error;
  String _sortOrder = 'newest'; // 'newest', 'oldest', 'confidence'

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize services
      await _databaseService.initialize();
      await _breedService.initialize();

      // Get recognition results from database
      final recognitionData = await _databaseService.getRecognitionResults(limit: 100);
      
      // Convert to RecognitionResult objects
      final List<RecognitionResult> results = [];
      
      for (final data in recognitionData) {
        try {
          // Get breed information
          final breed = _breedService.getBreedById(data['breed_id'] as String);
          if (breed != null) {
            final result = RecognitionResult(
              id: data['id'] as String,
              imagePath: data['image_path'] as String,
              predictedBreed: breed,
              confidence: (data['confidence'] as num).toDouble(),
              alternativePredictions: [], // Could parse this from JSON if needed
              timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
              processingTime: Duration(milliseconds: data['processing_time'] as int),
              modelVersion: data['model_version'] as String? ?? 'unknown',
            );
            results.add(result);
          }
        } catch (e) {
          print('⚠️ Error parsing recognition result: $e');
        }
      }

      if (mounted) {
        setState(() {
          _recognitionHistory = results;
          _isLoading = false;
        });
        _sortHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _sortHistory() {
    setState(() {
      switch (_sortOrder) {
        case 'newest':
          _recognitionHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          break;
        case 'oldest':
          _recognitionHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          break;
        case 'confidence':
          _recognitionHistory.sort((a, b) => b.confidence.compareTo(a.confidence));
          break;
      }
    });
  }

  void _setSortOrder(String order) {
    setState(() {
      _sortOrder = order;
    });
    _sortHistory();
  }

  Future<void> _deleteRecognition(RecognitionResult result) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Recognition'),
          content: Text('Are you sure you want to delete the recognition of ${result.predictedBreed.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await _databaseService.deleteRecognitionResult(result.id);
        if (success) {
          setState(() {
            _recognitionHistory.removeWhere((r) => r.id == result.id);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recognition deleted successfully'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete recognition'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting recognition: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _viewRecognitionDetails(RecognitionResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecognitionResultScreen(
          imagePath: result.imagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Recognition History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: _setSortOrder,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'newest',
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Text('Oldest First'),
              ),
              const PopupMenuItem(
                value: 'confidence',
                child: Text('Highest Confidence'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Loading history...',
                    style: AppTextStyles.bodyLarge,
                  ),
                ],
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _recognitionHistory.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading History',
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Recognition History',
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 12),
            Text(
              'Start recognizing cat breeds to see your history here!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back - user can use bottom navigation to go to home
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Recognizing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recognitionHistory.length,
        itemBuilder: (context, index) {
          final result = _recognitionHistory[index];
          return _buildHistoryCard(result);
        },
      ),
    );
  }

  Widget _buildHistoryCard(RecognitionResult result) {
    final timeAgo = _getTimeAgo(result.timestamp);
    final confidenceColor = _getConfidenceColor(result.confidence);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewRecognitionDetails(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cat breed image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  result.predictedBreed.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Breed info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.predictedBreed.name,
                            style: AppTextStyles.headline3.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: confidenceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: confidenceColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${(result.confidence * 100).toInt()}%',
                            style: AppTextStyles.caption.copyWith(
                              color: confidenceColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.predictedBreed.origin,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _deleteRecognition(result),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * _recognitionHistory.indexOf(result)));
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.successColor;
    if (confidence >= 0.6) return Colors.orange;
    return AppTheme.errorColor;
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 64,
              color: AppTheme.accentColor,
            ),
            SizedBox(height: 16),
            Text(
              'User Profile',
              style: AppTextStyles.headline2,
            ),
            SizedBox(height: 8),
            Text(
              'Settings and achievements',
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class RecognitionResultScreen extends StatefulWidget {
  final String imagePath;

  const RecognitionResultScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<RecognitionResultScreen> createState() => _RecognitionResultScreenState();
}

class _RecognitionResultScreenState extends State<RecognitionResultScreen> {
  bool _isProcessing = true;
  RecognitionResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _error = null;
      });

      // Initialize services if needed
      await MLService().initialize();
      await BreedDataService().initialize();
      await StatsService().initialize();
      await DatabaseService().initialize();
      
      // Process the image with ML service
      final result = await MLService().recognizeBreed(widget.imagePath);
      
      if (mounted) {
        if (result == null) {
          // ML service returned null - feature not implemented
          setState(() {
            _isProcessing = false;
            _result = null;
            _error = null; // Don't treat this as an error
          });
          print('🚫 MLService: Recognition not implemented - showing not implemented message');
        } else {
          // We have a real result - process it normally
          setState(() {
            _isProcessing = false;
            _result = result;
          });
          
          // Record recognition in stats and database only for real results
          // Save to database
          final databaseService = DatabaseService();
          final saved = await databaseService.saveRecognitionResult(result);
          
          if (saved) {
            print('💾 Database: Recognition saved successfully');
          } else {
            print('⚠️ Database: Failed to save recognition');
          }
          
          // Record in stats
          await StatsService().recordRecognition(result);
          print('📊 Stats updated for recognition: ${result.predictedBreed.name}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = e.toString();
        });
      }
    }
  }

  void _retryProcessing() {
    _processImage();
  }

  void _navigateToBreedDetail() {
    if (_result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BreedDetailScreen(breed: _result!.predictedBreed),
        ),
      );
    }
  }

  void _navigateToAR() {
    if (_result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ARScreen(
            breed: _result!.predictedBreed,
            recognitionResult: _result,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Recognition Result'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_result != null) ...[
            IconButton(
              onPressed: _navigateToAR,
              icon: const Icon(Icons.view_in_ar),
              tooltip: 'View in AR',
            ),
            IconButton(
              onPressed: () {
                // Share functionality
              },
              icon: const Icon(Icons.share),
              tooltip: 'Share Result',
            ),
          ],
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: LoadingPawAnimation(
                message: 'Analyzing your cat...',
                size: 60,
              ),
            )
          : _error != null
              ? _buildErrorView()
              : _result != null
                  ? _buildResultView()
                  : _buildNoResultView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Recognition Failed',
              style: AppTextStyles.headline2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An unknown error occurred',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _retryProcessing,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Cat Breed Recognition Unavailable',
              style: AppTextStyles.headline2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your trained EfficientNetV2-B3 model (15.9MB) exists in the app but cannot be used due to a technical limitation.\n\nThe TensorFlow Lite Flutter package has Android namespace conflicts that prevent compilation.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No fake results generated',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Technical Details:\n• EfficientNetV2-B3 model trained for 40+ cat breeds\n• Model file: 15.9MB in assets/models/model.tflite\n• Issue: tflite_flutter package Android namespace conflicts\n• Status: Awaiting dependency fix for compilation',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.blue.shade600,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    final breed = result.predictedBreed;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              image: DecorationImage(
                image: AssetImage(widget.imagePath),
                fit: BoxFit.cover,
                onError: (error, stackTrace) {},
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breed name and confidence
                _buildBreedHeader(breed, result),
                const SizedBox(height: 24),
                
                // Quick actions
                _buildQuickActions(),
                const SizedBox(height: 24),
                
                // Breed info summary
                _buildBreedSummary(breed),
                const SizedBox(height: 24),
                
                // Detailed predictions with percentages
                _buildDetailedPredictions(result),
                const SizedBox(height: 24),
                
                const SizedBox(height: 100), // Space for bottom actions
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreedHeader(CatBreed breed, RecognitionResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        breed.name,
                        style: AppTextStyles.headline2.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Origin: ${breed.origin}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(result.confidence),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    result.confidencePercentage,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              breed.description,
              style: AppTextStyles.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.successColor;
    if (confidence >= 0.6) return Colors.orange;
    return AppTheme.errorColor;
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.info_outline,
                    label: 'Learn More',
                    onPressed: _navigateToBreedDetail,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.view_in_ar,
                    label: 'View in AR',
                    onPressed: _navigateToAR,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildBreedSummary(CatBreed breed) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Breed Summary',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              icon: Icons.schedule,
              label: 'Life Span',
              value: breed.lifeSpan,
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              icon: Icons.fitness_center,
              label: 'Weight',
              value: breed.weight,
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              icon: Icons.mood,
              label: 'Temperament',
              value: breed.temperament,
            ),
            if (breed.isRare || breed.isHypoallergenic) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  if (breed.isRare)
                    Chip(
                      label: const Text('Rare Breed'),
                      backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                      labelStyle: const TextStyle(color: AppTheme.errorColor),
                    ),
                  if (breed.isHypoallergenic)
                    Chip(
                      label: const Text('Hypoallergenic'),
                      backgroundColor: AppTheme.successColor.withOpacity(0.1),
                      labelStyle: const TextStyle(color: AppTheme.successColor),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildDetailedPredictions(RecognitionResult result) {
    // Combine main prediction with alternatives for complete view
    final allPredictions = <PredictionScore>[
      PredictionScore(
        breed: result.predictedBreed,
        confidence: result.confidence,
        rank: 1,
      ),
      ...result.alternativePredictions,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Prediction Results',
                  style: AppTextStyles.headline3,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allPredictions.length} breeds detected',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'The AI model analyzed your cat photo and found these possible breed matches:',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...allPredictions.asMap().entries.map((entry) {
              final index = entry.key;
              final prediction = entry.value;
              final isMainPrediction = index == 0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPredictionRow(
                  prediction,
                  isMainPrediction: isMainPrediction,
                  rank: index + 1,
                ),
              );
            }),
            if (allPredictions.length > 1) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Multiple breeds detected! Your cat might be a mix or the AI found similar characteristics.',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildPredictionRow(
    PredictionScore prediction,
    {
      required bool isMainPrediction,
      required int rank,
    }
  ) {
    final percentage = (prediction.confidence * 100).toStringAsFixed(1);
    final confidenceColor = _getConfidenceColor(prediction.confidence);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMainPrediction 
            ? confidenceColor.withOpacity(0.05)
            : Colors.grey.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMainPrediction 
              ? confidenceColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: isMainPrediction ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isMainPrediction 
                      ? confidenceColor
                      : AppTheme.textSecondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Breed info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            prediction.breed.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: isMainPrediction 
                                  ? FontWeight.bold 
                                  : FontWeight.w500,
                              color: isMainPrediction 
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        if (isMainPrediction) 
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, 
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: confidenceColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'BEST MATCH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      prediction.breed.origin,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Confidence percentage
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentage%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: confidenceColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Confidence bar
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: prediction.confidence,
              child: Container(
                decoration: BoxDecoration(
                  color: confidenceColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Notification Service placeholder
class NotificationService {
  Future<void> initialize() async {
    // Initialize notification service
    print('Notification service initialized');
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
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
}