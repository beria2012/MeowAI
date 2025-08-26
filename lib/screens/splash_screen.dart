import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/theme.dart';
import '../services/ml_service.dart';
import '../services/breed_data_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _textAnimationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _startAnimations();
    
    // Safety timeout to force navigation if something hangs
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        print('⚠️ SplashScreen: Safety timeout reached, forcing navigation...');
        _navigateToHome();
      }
    });
  }

  void _startAnimations() async {
    print('🎬 SplashScreen: Starting animations and initialization...');
    
    try {
      // Start logo animation
      print('🎬 SplashScreen: Starting logo animation...');
      await _animationController.forward();
      print('✅ SplashScreen: Logo animation complete');
      
      // Start text animation
      print('🎬 SplashScreen: Starting text animation...');
      await _textAnimationController.forward();
      print('✅ SplashScreen: Text animation complete');
      
      // Initialize AI services
      print('🤖 SplashScreen: Starting AI services check...');
      await _initializeAIServices();
      print('✅ SplashScreen: AI services check complete');
      
      // Wait a bit more then navigate
      print('⏱️ SplashScreen: Final delay before navigation...');
      await Future.delayed(const Duration(milliseconds: 1000));
      
      print('🧭 SplashScreen: Attempting navigation to home screen...');
      await _navigateToHome();
      
    } catch (e) {
      print('❌ SplashScreen: Error in animation flow: $e');
      // Force navigation even if animations fail
      print('🚨 SplashScreen: Force navigating to home screen...');
      await _navigateToHome();
    }
  }
  
  Future<void> _navigateToHome() async {
    if (!mounted) {
      print('❌ SplashScreen: Widget not mounted, cannot navigate');
      return;
    }
    
    try {
      print('🧭 SplashScreen: Navigating to home screen...');
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
      print('✅ SplashScreen: Navigation completed successfully');
    } catch (e) {
      print('❌ SplashScreen: Navigation failed: $e');
      // Try simple replacement as fallback
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }
  
  /// Initialize AI services (ML model and comprehensive breed database)
  Future<void> _initializeAIServices() async {
    try {
      print('🤖 SplashScreen: Checking AI services with comprehensive database...');
      
      // Get singleton instances of services
      final breedService = BreedDataService();
      final mlService = MLService();
      
      print('  📚 SplashScreen: Checking comprehensive breed database...');
      print('    Current status: ${breedService.isInitialized ? "Already initialized" : "Needs initialization"}');
      
      // Initialize breed data service first (ML service depends on it)
      if (!breedService.isInitialized) {
        print('  📚 SplashScreen: Initializing comprehensive breed database...');
        await breedService.initialize().timeout(const Duration(seconds: 15));
        print('  ✅ SplashScreen: Comprehensive breed database loaded with ${breedService.getAllBreeds().length} breeds');
      } else {
        print('  ✅ SplashScreen: Comprehensive breed database already loaded (${breedService.getAllBreeds().length} breeds)');
      }
      
      print('  🧠 SplashScreen: Checking ML model for 223 breed recognition...');
      print('    Current status: ${mlService.isInitialized ? "Already initialized" : "Needs initialization"}');
      
      // Initialize ML service
      if (!mlService.isInitialized) {
        print('  🧠 SplashScreen: Initializing ML model...');
        await mlService.initialize().timeout(const Duration(seconds: 30));
        print('  ✅ SplashScreen: ML model ready for 223 breed recognition');
      } else {
        print('  ✅ SplashScreen: ML model already ready for 223 breed recognition');
      }
      
      print('🎉 SplashScreen: AI services check complete!');
    } catch (e) {
      print('❌ SplashScreen: Error with AI services: $e');
      // Continue anyway to prevent app from hanging
      print('⚠️ SplashScreen: Continuing to home screen anyway...');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo with cat animation
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
                  boxShadow: AppTheme.softShadow,
                ),
                child: const Center(
                  child: Icon(
                    Icons.pets,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
                  .animate(controller: _animationController)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 48),

              // App name
              Text(
                'MeowAI',
                style: AppTextStyles.headline1.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate(controller: _textAnimationController)
                  .slideY(
                    begin: 0.5,
                    end: 0,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 800.ms),

              const SizedBox(height: 16),

              // App tagline
              Text(
                'Discover Your Cat\'s Breed',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                ),
              )
                  .animate(controller: _textAnimationController)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(
                    delay: 200.ms,
                    duration: 600.ms,
                  ),

              const SizedBox(height: 64),

              // Running cat paws animation
              const SizedBox(
                height: 80,
                width: double.infinity,
                child: RunningCatPawsAnimation(),
              ),

              const SizedBox(height: 24),

              Text(
                'Loading AI Model...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .fadeIn(duration: 1500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// Running cat paws animation widget
class RunningCatPawsAnimation extends StatefulWidget {
  const RunningCatPawsAnimation({super.key});

  @override
  State<RunningCatPawsAnimation> createState() => _RunningCatPawsAnimationState();
}

class _RunningCatPawsAnimationState extends State<RunningCatPawsAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late List<AnimationController> _pawControllers;
  late List<Animation<Offset>> _pawAnimations;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;

  final int _numberOfPaws = 6;
  final List<Color> _pawColors = [
    Colors.white,
    Colors.white.withOpacity(0.9),
    Colors.white.withOpacity(0.8),
    Colors.white.withOpacity(0.9),
    Colors.white,
    Colors.white.withOpacity(0.85),
  ];

  @override
  void initState() {
    super.initState();
    
    // Main controller for the overall animation cycle
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Individual controllers for each paw
    _pawControllers = List.generate(
      _numberOfPaws,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)), // Staggered durations
        vsync: this,
      ),
    );

    // Create animations for each paw
    _pawAnimations = [];
    _scaleAnimations = [];
    _opacityAnimations = [];

    for (int i = 0; i < _numberOfPaws; i++) {
      // Position animation - paws run from left to right
      _pawAnimations.add(
        Tween<Offset>(
          begin: Offset(-0.2 - (i * 0.15), 0.0), // Start off-screen left, staggered
          end: Offset(1.2 + (i * 0.1), 0.0),     // End off-screen right
        ).animate(
          CurvedAnimation(
            parent: _pawControllers[i],
            curve: Curves.easeInOut,
          ),
        ),
      );

      // Scale animation - paws get bigger/smaller as they move
      _scaleAnimations.add(
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.2)
                .chain(CurveTween(curve: Curves.elasticOut)),
            weight: 30,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.2, end: 0.8)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 40,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.8, end: 0.0)
                .chain(CurveTween(curve: Curves.easeIn)),
            weight: 30,
          ),
        ]).animate(_pawControllers[i]),
      );

      // Opacity animation - fade in and out
      _opacityAnimations.add(
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            weight: 25,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.0),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.0),
            weight: 25,
          ),
        ]).animate(_pawControllers[i]),
      );
    }

    _startAnimation();
    
    // Start sparkle effects
    _mainController.repeat();
  }

  void _startAnimation() async {
    // Start all paw animations with staggered delays
    for (int i = 0; i < _numberOfPaws; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _pawControllers[i].forward().then((_) {
            if (mounted) {
              _pawControllers[i].reset();
            }
          });
        }
      });
    }

    // Repeat the entire sequence
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    for (var controller in _pawControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background track/path indicator
        Positioned.fill(
          child: Center(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
        // Animated paws
        ...List.generate(_numberOfPaws, (index) {
          return AnimatedBuilder(
            animation: Listenable.merge([
              _pawAnimations[index],
              _scaleAnimations[index],
              _opacityAnimations[index],
            ]),
            builder: (context, child) {
              return Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: FractionalTranslation(
                    translation: _pawAnimations[index].value,
                    child: Transform.scale(
                      scale: _scaleAnimations[index].value,
                      child: Opacity(
                        opacity: _opacityAnimations[index].value,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: _pawColors[index].withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.pets,
                            color: _pawColors[index],
                            size: 28 + (index % 2) * 4, // Slightly different sizes
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
        
        // Subtle sparkle effects
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Positioned(
                left: 60.0 + (index * 80),
                top: 10 + (index % 2) * 15,
                child: Opacity(
                  opacity: (0.3 + (index * 0.2)) * 
                      (0.5 + 0.5 * 
                      sin(2 * pi * (_mainController.value + index * 0.33))),
                  child: Icon(
                    Icons.star,
                    color: Colors.white.withOpacity(0.6),
                    size: 8 + (index * 2),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}