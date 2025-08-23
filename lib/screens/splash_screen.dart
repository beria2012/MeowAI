import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../utils/theme.dart';
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
  }

  void _startAnimations() async {
    // Start logo animation
    await _animationController.forward();
    
    // Start text animation
    await _textAnimationController.forward();
    
    // Wait a bit more then navigate
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
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

              // Loading indicator
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 1500.ms,
                    color: Colors.white.withOpacity(0.5),
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

// Custom cat paw loading animation widget
class CatPawLoader extends StatefulWidget {
  const CatPawLoader({super.key});

  @override
  State<CatPawLoader> createState() => _CatPawLoaderState();
}

class _CatPawLoaderState extends State<CatPawLoader>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        _controllers[i].forward().then((_) {
          if (mounted) {
            _controllers[i].reverse();
          }
        });
      }
    }
    
    // Repeat the animation
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _animations[index].value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}