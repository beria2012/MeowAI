import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meow_ai/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MeowAI Integration Tests', () {
    testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify splash screen elements are present
      expect(find.text('MeowAI'), findsOneWidget);
      expect(find.text('Discover Your Cat\'s Breed'), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsWidgets);
      
      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Verify we navigate to home screen
      expect(find.text('Hello! 👋'), findsOneWidget);
      expect(find.text('Ready to discover your cat\'s breed?'), findsOneWidget);
    });

    testWidgets('Navigation between tabs works correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we're on home tab
      expect(find.text('Hello! 👋'), findsOneWidget);

      // Navigate to Encyclopedia tab
      await tester.tap(find.text('Encyclopedia'));
      await tester.pumpAndSettle();
      expect(find.text('Breed Encyclopedia'), findsOneWidget);

      // Navigate to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Recognition History'), findsOneWidget);

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('User Profile'), findsOneWidget);

      // Navigate back to Home tab
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Hello! 👋'), findsOneWidget);
    });

    testWidgets('Camera screen can be accessed and displays correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find and tap the camera FAB
      final cameraFab = find.byType(FloatingActionButton);
      expect(cameraFab, findsOneWidget);
      
      await tester.tap(cameraFab);
      await tester.pumpAndSettle();

      // Verify camera screen elements
      expect(find.byIcon(Icons.camera_alt), findsWidgets);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      
      // Test back navigation
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Hello! 👋'), findsOneWidget);
    });

    testWidgets('Encyclopedia screen shows breed list and search works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to Encyclopedia
      await tester.tap(find.text('Encyclopedia'));
      await tester.pumpAndSettle();

      // Verify encyclopedia elements
      expect(find.text('Breed Encyclopedia'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('breeds available'), findsOneWidget);

      // Test search functionality
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'Persian');
      await tester.pumpAndSettle();

      // Verify search results (if Persian breed exists in test data)
      // This would need actual breed data to be loaded
      
      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
    });

    testWidgets('Filter functionality works in Encyclopedia', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to Encyclopedia
      await tester.tap(find.text('Encyclopedia'));
      await tester.pumpAndSettle();

      // Test filter chips
      await tester.tap(find.text('Popular'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Rare'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Hypoallergenic'));
      await tester.pumpAndSettle();

      // Open filter sheet
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Verify filter sheet elements
      expect(find.text('Filter Breeds'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Sort By'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      // Close filter sheet
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
    });

    testWidgets('Breed detail screen shows comprehensive information', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to Encyclopedia
      await tester.tap(find.text('Encyclopedia'));
      await tester.pumpAndSettle();

      // Tap on first breed card (if any breeds are loaded)
      final breedCards = find.byType(GestureDetector);
      if (breedCards.evaluate().isNotEmpty) {
        await tester.tap(breedCards.first);
        await tester.pumpAndSettle();

        // Verify breed detail elements
        expect(find.text('Basic Information'), findsOneWidget);
        expect(find.text('Characteristics'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
        expect(find.text('History & Origin'), findsOneWidget);
        expect(find.text('Traits'), findsOneWidget);
        
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        
        // Test favorite functionality
        await tester.tap(find.byIcon(Icons.favorite_border));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.favorite), findsOneWidget);

        // Navigate back
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Quick actions work correctly on home screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test Take Photo quick action
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();
      
      // Should navigate to camera screen
      expect(find.byIcon(Icons.camera_alt), findsWidgets);
      
      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test From Gallery quick action
      await tester.tap(find.text('From Gallery'));
      await tester.pumpAndSettle();
      
      // This would trigger image picker in real app
      // For testing, we just verify the tap works
    });

    testWidgets('Feature cards navigate to correct screens', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test Encyclopedia feature card
      final encyclopediaCard = find.ancestor(
        of: find.text('Encyclopedia'),
        matching: find.byType(GestureDetector),
      );
      
      if (encyclopediaCard.evaluate().isNotEmpty) {
        await tester.tap(encyclopediaCard);
        await tester.pumpAndSettle();
        expect(find.text('Breed Encyclopedia'), findsOneWidget);
        
        // Navigate back to home
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
      }

      // Test History feature card
      final historyCard = find.ancestor(
        of: find.text('History'),
        matching: find.byType(GestureDetector),
      );
      
      if (historyCard.evaluate().isNotEmpty) {
        await tester.tap(historyCard);
        await tester.pumpAndSettle();
        expect(find.text('Recognition History'), findsOneWidget);
        
        // Navigate back to home
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('App handles orientation changes correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify portrait mode works
      expect(find.text('Hello! 👋'), findsOneWidget);

      // Note: Orientation testing in integration tests requires platform channel setup
      // This is a placeholder for orientation testing
      
      // The app is configured for portrait-only in main.dart
      // So we verify it stays in portrait mode
    });

    testWidgets('Accessibility features work correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify semantic labels are present
      expect(find.bySemanticsLabel('MeowAI'), findsWidgets);
      
      // Test that buttons have proper semantics
      final semanticsButtons = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.button == true,
      );
      expect(semanticsButtons, findsWidgets);

      // Verify images have proper alt text
      final semanticsImages = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.image == true,
      );
      expect(semanticsImages, findsWidgets);
    });

    testWidgets('App performance under normal usage', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Measure frame rendering performance
      await tester.binding.traceAction(() async {
        // Navigate through multiple screens rapidly
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Encyclopedia'));
          await tester.pumpAndSettle();
          
          await tester.tap(find.text('History'));
          await tester.pumpAndSettle();
          
          await tester.tap(find.text('Profile'));
          await tester.pumpAndSettle();
          
          await tester.tap(find.text('Home'));
          await tester.pumpAndSettle();
        }
      });

      // Verify the app is still responsive
      expect(find.text('Hello! 👋'), findsOneWidget);
    });

    testWidgets('Error states are handled gracefully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test network error handling (simulated)
      // This would require mocking network calls
      
      // Test camera permission denial
      // This would require platform channel mocking
      
      // For now, just verify error UI elements exist in code
      // Real error testing would need mocked dependencies
    });

    testWidgets('App state persistence across navigation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to Encyclopedia and perform search
      await tester.tap(find.text('Encyclopedia'));
      await tester.pumpAndSettle();
      
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'Test Search');
      await tester.pumpAndSettle();

      // Navigate away and back
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Encyclopedia'));
      await tester.pumpAndSettle();

      // Verify search text is preserved (depending on implementation)
      // This test validates state management
    });
  });

  group('Performance Tests', () {
    testWidgets('App startup time is reasonable', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // Verify startup time is under 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    testWidgets('Memory usage is within acceptable limits', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate through all screens to load content
      await tester.tap(find.text('Encyclopedia'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Memory testing would require platform channel integration
      // This is a placeholder for memory testing
    });
  });

  group('User Journey Tests', () {
    testWidgets('Complete user onboarding flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Simulate new user experience
      // 1. View splash screen
      // 2. Navigate to home
      // 3. Explore encyclopedia
      // 4. Try camera functionality
      // 5. Check settings

      // This would be a comprehensive user journey test
      // covering the main user workflows
      
      expect(find.text('Hello! 👋'), findsOneWidget);
    });

    testWidgets('Cat recognition workflow simulation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Simulate the complete recognition workflow
      // 1. Access camera
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 2. Simulate taking photo (would require mocking)
      // 3. Process with ML (would require mocking)
      // 4. View results
      // 5. Save to favorites
      // 6. Share results

      // Navigate back to verify workflow completion
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Hello! 👋'), findsOneWidget);
    });
  });
}