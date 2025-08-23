import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/theme.dart';
import '../widgets/cat_paw_button.dart';
import '../models/cat_breed.dart';
import '../models/recognition_result.dart';
import '../services/ml_service.dart';
import '../services/breed_data_service.dart';
import 'ar_screen.dart';
import 'breed_detail_screen.dart';

class EncyclopediaScreen extends StatelessWidget {
  const EncyclopediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encyclopedia'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Cat Breed Encyclopedia',
              style: AppTextStyles.headline2,
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppTheme.secondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Recognition History',
              style: AppTextStyles.headline2,
            ),
            SizedBox(height: 8),
            Text(
              'Your past recognitions will appear here',
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
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
      
      // Process the image with ML service
      final result = await MLService().recognizeBreed(widget.imagePath);
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _result = result;
        });
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
              Icons.pets,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Cat Detected',
              style: AppTextStyles.headline2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We couldn\'t detect a cat in this image. Please try with a clearer photo.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Try Another Photo'),
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
                
                // Alternative predictions
                if (result.alternativePredictions.isNotEmpty)
                  _buildAlternativePredictions(result.alternativePredictions),
                
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

  Widget _buildAlternativePredictions(List<PredictionScore> alternatives) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alternative Predictions',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 16),
            ...alternatives.take(3).map((prediction) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prediction.breed.name,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(prediction.confidence * 100).toInt()}%',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.3, end: 0);
  }
}

// Notification Service placeholder
class NotificationService {
  Future<void> initialize() async {
    // Initialize notification service
    print('Notification service initialized');
  }
}

// Database Service placeholder
class DatabaseService {
  Future<void> initialize() async {
    // Initialize database
    print('Database service initialized');
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