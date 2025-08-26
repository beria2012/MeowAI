import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/theme.dart';
import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/breed_data_service.dart';
import '../widgets/cat_paw_button.dart';
import 'camera_screen.dart';
import 'basic_screens.dart';
import 'ar_screen.dart';
import 'favorites_screen.dart';
import 'share_screen.dart';
import 'more_features_screen.dart';
import 'model_demo_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen: Starting initialization...');
    
    _pageController = PageController();
    print('🏠 HomeScreen: PageController created');
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    print('🏠 HomeScreen: Animation controller created');
    
    // Initialize services
    print('🏠 HomeScreen: Starting service initialization...');
    _initializeServices();
    print('🏠 HomeScreen: Service initialization started (async)');
  }

  Future<void> _initializeServices() async {
    try {
      print('🏠 HomeScreen: Initializing home screen services...');
      
      // Add timeout to prevent hanging
      await Future.any([
        _initializeServicesWithTimeout(),
        Future.delayed(const Duration(seconds: 15), () => throw TimeoutException('Service initialization timed out', const Duration(seconds: 15))),
      ]);
      
      print('🏠 HomeScreen: Service initialization completed successfully');
    } on TimeoutException {
      print('⚠️ HomeScreen: Service initialization timed out - some services may not be available');
    } catch (e) {
      print('❌ HomeScreen: Error initializing services: $e');
    }
  }
  
  /// Initialize services with timeout helper
  Future<void> _initializeServicesWithTimeout() async {
    print('🏠 HomeScreen: Starting camera service...');
    final cameraResult = await CameraService().initialize().catchError((e) {
      print('❌ HomeScreen: Camera service initialization failed: $e');
      return false;
    });
    print('🏠 HomeScreen: Camera service result: $cameraResult');
    
    print('🏠 HomeScreen: Starting ML service...');
    final mlResult = await MLService().initialize().catchError((e) {
      print('❌ HomeScreen: ML service initialization failed: $e');
      return false;
    });
    print('🏠 HomeScreen: ML service result: $mlResult');
    
    print('🏠 HomeScreen: Starting breed data service...');
    final breedResult = await BreedDataService().initialize().catchError((e) {
      print('❌ HomeScreen: Breed data service initialization failed: $e');
      return false;
    });
    print('🏠 HomeScreen: Breed data service result: $breedResult');
    
    final results = [cameraResult, mlResult, breedResult];
    final successCount = results.where((r) => r == true).length;
    print('🏠 HomeScreen: Services initialized: $successCount/3 successful');
    
    // Show notification about new Kaggle model
    if (mlResult && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.star, color: Colors.yellow),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🎉 Real Model Loaded! Your trained EfficientNetV2-B3 model recognizing 40 cat breeds is now active',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Animate FAB based on current page
    if (index == 0) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _onBottomNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _HomeTab(),
          const EncyclopediaScreen(),
          const HistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: AppTheme.cardShadow,
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        height: 60, // Explicit height
        padding: EdgeInsets.zero, // Remove default padding
        child: Container(
          height: 60,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildBottomNavItem(
                icon: Icons.home,
                label: 'Home',
                index: 0,
              ),
              _buildBottomNavItem(
                icon: Icons.book,
                label: 'Guides',
                index: 1,
              ),
              const SizedBox(width: 48), // Space for FAB
              _buildBottomNavItem(
                icon: Icons.history,
                label: 'History',
                index: 2,
              ),
              _buildBottomNavItem(
                icon: Icons.person,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: Tween<double>(begin: 0.8, end: 1.0)
              .animate(CurvedAnimation(
                parent: _fabAnimationController,
                curve: Curves.easeInOut,
              ))
              .value,
          child: CatPawButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
            },
            size: 64,
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatefulWidget {
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  Widget build(BuildContext context) {
    print('🏠 _HomeTab: Building home tab widget...');
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get precise screen measurements
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final topPadding = mediaQuery.padding.top;
        final bottomPadding = mediaQuery.padding.bottom;
        
        // Account for bottom navigation (60px) + floating button space (14px)
        final bottomNavSpace = 74.0;
        
        // Calculate exact content height to prevent overflow
        final maxContentHeight = screenHeight - topPadding - bottomNavSpace - bottomPadding;
        
        print('🏠 Screen: ${screenHeight}px, Top: ${topPadding}px, Bottom: ${bottomPadding}px, Content: ${maxContentHeight}px');
        
        return Scaffold(
          body: SafeArea(
            bottom: false, // Manual bottom control
            child: SizedBox(
              height: maxContentHeight,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 20, // Reduced buffer for bottom nav
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    const BreedOfTheDayCard(),
                    const SizedBox(height: 24),
                    const StatsOverviewCard(),
                    const SizedBox(height: 24),
                    _buildFeaturesSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
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
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello! 👋',
                    style: AppTextStyles.headline2.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to discover your cat\'s breed?',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
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
              child: _QuickActionCard(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Capture a cat',
                gradient: AppTheme.primaryGradient,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.photo_library,
                title: 'From Gallery',
                subtitle: 'Choose photo',
                gradient: AppTheme.secondaryGradient,
                onTap: () {
                  _pickImageFromGallery();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.psychology,
                title: 'Model Demo',
                subtitle: 'See trained AI',
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ModelDemoScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.book,
                title: 'Encyclopedia',
                subtitle: 'Browse breeds',
                gradient: const LinearGradient(
                  colors: [Colors.teal, Colors.cyan],
                ),
                onTap: () {
                  // Navigate to encyclopedia tab
                  final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                  homeState?._onBottomNavTapped(1);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _pickImageFromGallery() async {
    try {
      print('🖼️ HomeScreen: Opening gallery picker...');
      
      // Use camera service to pick image from gallery
      final cameraService = CameraService();
      final imagePath = await cameraService.pickImageFromGallery();
      
      if (imagePath != null && mounted) {
        print('🖼️ HomeScreen: Image selected from gallery: $imagePath');
        
        // Navigate to recognition result screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecognitionResultScreen(
              imagePath: imagePath,
            ),
          ),
        );
      } else if (mounted) {
        print('🖼️ HomeScreen: Gallery picker was cancelled');
        // User cancelled gallery picker - no action needed
      }
    } on PermissionException catch (permissionError) {
      print('❌ HomeScreen: Permission error: $permissionError');
      
      if (mounted) {
        _showPermissionDialog(
          title: 'Photo Access Required',
          message: permissionError.message,
          canOpenSettings: permissionError.canOpenSettings,
        );
      }
    } catch (e) {
      print('❌ HomeScreen: Error opening gallery: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to open gallery: ${e.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _pickImageFromGallery,
            ),
          ),
        );
      }
    }
  }

  void _showPermissionDialog({
    required String title,
    required String message,
    required bool canOpenSettings,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.accentColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headline3.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            if (canOpenSettings)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final cameraService = CameraService();
                  await cameraService.openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Settings'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery(); // Retry
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore Features',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            FeatureCard(
              icon: Icons.book,
              title: 'Encyclopedia',
              description: 'Learn about cat breeds',
              color: AppTheme.primaryColor,
              onTap: () {
                // Navigate to encyclopedia tab
                final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                homeState?._onBottomNavTapped(1);
              },
            ),
            FeatureCard(
              icon: Icons.history,
              title: 'History',
              description: 'View past recognitions',
              color: AppTheme.secondaryColor,
              onTap: () {
                // Navigate to history tab
                final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                homeState?._onBottomNavTapped(2);
              },
            ),
            FeatureCard(
              icon: Icons.favorite,
              title: 'Favorites',
              description: 'Saved breeds & photos',
              color: AppTheme.errorColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesScreen(),
                  ),
                );
              },
            ),
            FeatureCard(
              icon: Icons.share,
              title: 'Share',
              description: 'Share your discoveries',
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShareScreen(),
                  ),
                );
              },
            ),
            FeatureCard(
              icon: Icons.view_in_ar,
              title: 'AR View',
              description: 'Experience cats in AR',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ARScreen(),
                  ),
                );
              },
            ),
            FeatureCard(
              icon: Icons.eco,
              title: 'More Features',
              description: 'Additional tools & settings',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MoreFeaturesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.headline3.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}