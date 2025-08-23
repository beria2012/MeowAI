import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/theme.dart';
import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/breed_data_service.dart';
import '../widgets/cat_paw_button.dart';
import 'camera_screen.dart';
import 'basic_screens.dart';
import 'ar_screen.dart';

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
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Initialize services
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      print('Initializing home screen services...');
      
      // Add timeout to prevent hanging
      await Future.any([
        _initializeServicesWithTimeout(),
        Future.delayed(Duration(seconds: 15), () => throw TimeoutException('Service initialization timed out', Duration(seconds: 15))),
      ]);
      
      print('Service initialization completed');
    } on TimeoutException {
      print('Service initialization timed out - some services may not be available');
    } catch (e) {
      print('Error initializing services: $e');
    }
  }
  
  /// Initialize services with timeout helper
  Future<void> _initializeServicesWithTimeout() async {
    final results = await Future.wait([
      CameraService().initialize().catchError((e) {
        print('Camera service initialization failed: $e');
        return false;
      }),
      MLService().initialize().catchError((e) {
        print('ML service initialization failed: $e');
        return false;
      }),
      BreedDataService().initialize().catchError((e) {
        print('Breed data service initialization failed: $e');
        return false;
      }),
    ]);
    
    final successCount = results.where((r) => r == true).length;
    print('Services initialized: $successCount/3 successful');
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
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.home,
                label: 'Home',
                index: 0,
              ),
              _buildBottomNavItem(
                icon: Icons.book,
                label: 'Encyclopedia',
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ).animate(target: isSelected ? 1 : 0)
        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1));
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.elasticOut,
        ),
      ),
      child: CatPawButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        size: 64,
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
            _buildFeaturesSection(context),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
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
            )
                .animate()
                .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
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
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 800.ms)
                      .slideX(begin: 0.2, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to discover your cat\'s breed?',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 800.ms)
                      .slideX(begin: 0.2, end: 0),
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
        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
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
                  // Navigator.push to camera screen
                },
              ).animate().slideX(delay: 700.ms, begin: -0.3, end: 0),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.photo_library,
                title: 'From Gallery',
                subtitle: 'Choose photo',
                gradient: AppTheme.secondaryGradient,
                onTap: () {
                  // Pick from gallery
                },
              ).animate().slideX(delay: 800.ms, begin: 0.3, end: 0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore Features',
          style: AppTextStyles.headline3,
        ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
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
              onTap: () {},
            ).animate().scale(delay: 1000.ms, duration: 600.ms),
            FeatureCard(
              icon: Icons.history,
              title: 'History',
              description: 'View past recognitions',
              color: AppTheme.secondaryColor,
              onTap: () {},
            ).animate().scale(delay: 1100.ms, duration: 600.ms),
            FeatureCard(
              icon: Icons.favorite,
              title: 'Favorites',
              description: 'Saved breeds & photos',
              color: AppTheme.errorColor,
              onTap: () {},
            ).animate().scale(delay: 1200.ms, duration: 600.ms),
            FeatureCard(
              icon: Icons.share,
              title: 'Share',
              description: 'Share your discoveries',
              color: AppTheme.accentColor,
              onTap: () {},
            ).animate().scale(delay: 1300.ms, duration: 600.ms),
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
            ).animate().scale(delay: 1400.ms, duration: 600.ms),
            FeatureCard(
              icon: Icons.eco,
              title: 'More Features',
              description: 'Coming soon...',
              color: Colors.green,
              onTap: () {},
            ).animate().scale(delay: 1500.ms, duration: 600.ms),
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