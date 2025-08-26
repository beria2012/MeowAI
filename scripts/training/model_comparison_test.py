#!/usr/bin/env python3
"""
Model Comparison Test Script
============================
Tests and compares the full H5 model vs mobile TFLite model on test images.
Provides detailed analysis of accuracy, confidence, and performance differences.
"""

import os
import json
import time
import numpy as np
import tensorflow as tf
from PIL import Image, ImageOps
from pathlib import Path
from datetime import datetime
from tensorflow.keras.applications.efficientnet_v2 import preprocess_input

class ModelComparator:
    def __init__(self):
        """Initialize the model comparator with paths and class indices"""
        
        # Paths
        self.script_dir = Path(__file__).parent
        self.h5_model_path = self.script_dir / "all_breeds_high_accuracy_v1_final.h5"
        self.tflite_model_path = Path(__file__).parent.parent.parent / "assets/models/model.tflite"
        self.class_indices_path = self.script_dir / "class_indices.json"
        self.test_images_dir = self.script_dir / "test"
        
        # Model parameters
        self.input_size = (384, 384)  # Based on EfficientNetV2-B3
        
        # Load class indices
        with open(self.class_indices_path, 'r') as f:
            self.class_indices = json.load(f)
        
        # Create reverse mapping (index -> breed name)
        self.index_to_breed = {v: k for k, v in self.class_indices.items()}
        
        # Models
        self.h5_model = None
        self.tflite_interpreter = None
        
        # Results storage
        self.comparison_results = []
        
        print(f"🔧 Initialized Model Comparator")
        print(f"📂 H5 Model: {self.h5_model_path}")
        print(f"📱 TFLite Model: {self.tflite_model_path}")
        print(f"🧪 Test Images: {self.test_images_dir}")
        print(f"🏷️ Classes: {len(self.class_indices)} breeds")
    
    def load_models(self):
        """Load both H5 and TFLite models"""
        
        print("\n🔄 Loading Models...")
        
        try:
            # Load H5 model
            print("📥 Loading H5 model...")
            self.h5_model = tf.keras.models.load_model(str(self.h5_model_path))
            h5_size = self.h5_model_path.stat().st_size / (1024 * 1024)
            print(f"✅ H5 model loaded successfully ({h5_size:.1f} MB)")
            
            # Load TFLite model
            print("📱 Loading TFLite model...")
            self.tflite_interpreter = tf.lite.Interpreter(model_path=str(self.tflite_model_path))
            self.tflite_interpreter.allocate_tensors()
            tflite_size = self.tflite_model_path.stat().st_size / (1024 * 1024)
            print(f"✅ TFLite model loaded successfully ({tflite_size:.1f} MB)")
            
            # Get TFLite input/output details
            self.tflite_input_details = self.tflite_interpreter.get_input_details()
            self.tflite_output_details = self.tflite_interpreter.get_output_details()
            
            print(f"📊 Size comparison: H5 {h5_size:.1f}MB → TFLite {tflite_size:.1f}MB")
            print(f"📉 Size reduction: {((h5_size - tflite_size) / h5_size * 100):.1f}%")
            
            return True
            
        except Exception as e:
            print(f"❌ Error loading models: {e}")
            return False
    
    def preprocess_image(self, image_path):
        """Preprocess image for model input using EfficientNetV2 preprocessing"""
        
        try:
            # Load image using Keras utilities (same as evaluate_on_test.py)
            image = tf.keras.preprocessing.image.load_img(
                str(image_path), 
                target_size=self.input_size
            )
            
            # Convert to array
            image_array = tf.keras.preprocessing.image.img_to_array(image)
            
            # Add batch dimension
            image_batch = np.expand_dims(image_array, axis=0)
            
            # Apply EfficientNetV2 preprocessing (critical step!)
            image_batch = preprocess_input(image_batch)
            
            return image_batch
            
        except Exception as e:
            print(f"❌ Error preprocessing image {image_path}: {e}")
            return None
    
    def predict_h5(self, image_batch):
        """Make prediction using H5 model"""
        
        try:
            start_time = time.time()
            predictions = self.h5_model.predict(image_batch, verbose=0)
            processing_time = time.time() - start_time
            
            # Get top prediction
            predicted_index = np.argmax(predictions[0])
            confidence = float(predictions[0][predicted_index])
            predicted_breed = self.index_to_breed[predicted_index]
            
            # Get top 3 predictions
            top_3_indices = np.argsort(predictions[0])[-3:][::-1]
            top_3_predictions = []
            
            for idx in top_3_indices:
                breed_name = self.index_to_breed[idx]
                breed_confidence = float(predictions[0][idx])
                top_3_predictions.append({
                    'breed': breed_name,
                    'confidence': breed_confidence
                })
            
            return {
                'predicted_breed': predicted_breed,
                'confidence': confidence,
                'processing_time': processing_time,
                'top_3': top_3_predictions,
                'raw_predictions': predictions[0].tolist()
            }
            
        except Exception as e:
            print(f"❌ Error in H5 prediction: {e}")
            return None
    
    def predict_tflite(self, image_batch):
        """Make prediction using TFLite model"""
        
        try:
            start_time = time.time()
            
            # Set input tensor
            self.tflite_interpreter.set_tensor(
                self.tflite_input_details[0]['index'], 
                image_batch
            )
            
            # Run inference
            self.tflite_interpreter.invoke()
            
            # Get output tensor
            predictions = self.tflite_interpreter.get_tensor(
                self.tflite_output_details[0]['index']
            )
            
            processing_time = time.time() - start_time
            
            # Get top prediction
            predicted_index = np.argmax(predictions[0])
            confidence = float(predictions[0][predicted_index])
            predicted_breed = self.index_to_breed[predicted_index]
            
            # Get top 3 predictions
            top_3_indices = np.argsort(predictions[0])[-3:][::-1]
            top_3_predictions = []
            
            for idx in top_3_indices:
                breed_name = self.index_to_breed[idx]
                breed_confidence = float(predictions[0][idx])
                top_3_predictions.append({
                    'breed': breed_name,
                    'confidence': breed_confidence
                })
            
            return {
                'predicted_breed': predicted_breed,
                'confidence': confidence,
                'processing_time': processing_time,
                'top_3': top_3_predictions,
                'raw_predictions': predictions[0].tolist()
            }
            
        except Exception as e:
            print(f"❌ Error in TFLite prediction: {e}")
            return None
    
    def test_single_image(self, image_path):
        """Test a single image with both models"""
        
        print(f"\n📸 Testing: {image_path.name}")
        
        # Preprocess image
        image_batch = self.preprocess_image(image_path)
        if image_batch is None:
            return None
        
        # Test with H5 model
        print("  🧠 Testing with H5 model...")
        h5_result = self.predict_h5(image_batch)
        
        # Test with TFLite model
        print("  📱 Testing with TFLite model...")
        tflite_result = self.predict_tflite(image_batch)
        
        if h5_result is None or tflite_result is None:
            return None
        
        # Compare results
        same_prediction = h5_result['predicted_breed'] == tflite_result['predicted_breed']
        confidence_diff = abs(h5_result['confidence'] - tflite_result['confidence'])
        speed_ratio = h5_result['processing_time'] / tflite_result['processing_time']
        
        result = {
            'image_name': image_path.name,
            'h5': h5_result,
            'tflite': tflite_result,
            'comparison': {
                'same_prediction': same_prediction,
                'confidence_difference': confidence_diff,
                'speed_ratio': speed_ratio
            }
        }
        
        # Debug predictions for the first image to understand the issue
        if image_path.name == "1.jpg":
            self.debug_predictions(image_path.name, h5_result, tflite_result)
        
        # Print immediate results
        print(f"    H5:     {h5_result['predicted_breed']} ({h5_result['confidence']:.3f}) - {h5_result['processing_time']:.3f}s")
        print(f"    TFLite: {tflite_result['predicted_breed']} ({tflite_result['confidence']:.3f}) - {tflite_result['processing_time']:.3f}s")
        print(f"    Match: {'✅' if same_prediction else '❌'} | Confidence Δ: {confidence_diff:.3f} | Speed: {speed_ratio:.1f}x")
        
        return result
        
    def analyze_test_images(self):
        """Analyze test images to understand what breeds they contain"""
        
        print("\n🔍 ANALYZING TEST IMAGES:")
        print("-" * 40)
        
        image_extensions = {'.jpg', '.jpeg', '.png'}
        test_images = [
            f for f in self.test_images_dir.iterdir() 
            if f.suffix.lower() in image_extensions
        ]
        
        for image_path in sorted(test_images):
            # Get image file info
            file_size = image_path.stat().st_size / 1024  # KB
            
            try:
                # Load image to get dimensions
                image = tf.keras.preprocessing.image.load_img(str(image_path))
                width, height = image.size
                
                print(f"📸 {image_path.name}: {width}x{height}, {file_size:.1f}KB")
                
            except Exception as e:
                print(f"❌ Error analyzing {image_path.name}: {e}")
    
    def debug_predictions(self, image_name, h5_result, tflite_result):
        """Debug predictions in detail for suspicious results"""
        
        print(f"\n🐛 DEBUG PREDICTIONS FOR {image_name}:")
        print("-" * 50)
        
        # Analyze H5 predictions
        h5_preds = np.array(h5_result['raw_predictions'])
        h5_max = np.max(h5_preds)
        h5_min = np.min(h5_preds)
        h5_std = np.std(h5_preds)
        h5_top5_indices = np.argsort(h5_preds)[-5:][::-1]
        
        print(f"🧠 H5 Model Analysis:")
        print(f"   Max prediction: {h5_max:.6f}")
        print(f"   Min prediction: {h5_min:.6f}")
        print(f"   Std deviation: {h5_std:.6f}")
        print(f"   Top 5 predictions:")
        for i, idx in enumerate(h5_top5_indices):
            breed = self.index_to_breed[idx]
            conf = h5_preds[idx]
            print(f"     {i+1}. {breed}: {conf:.6f}")
        
        # Analyze TFLite predictions
        tflite_preds = np.array(tflite_result['raw_predictions'])
        tflite_max = np.max(tflite_preds)
        tflite_min = np.min(tflite_preds)
        tflite_std = np.std(tflite_preds)
        tflite_top5_indices = np.argsort(tflite_preds)[-5:][::-1]
        
        print(f"\n📱 TFLite Model Analysis:")
        print(f"   Max prediction: {tflite_max:.6f}")
        print(f"   Min prediction: {tflite_min:.6f}")
        print(f"   Std deviation: {tflite_std:.6f}")
        print(f"   Top 5 predictions:")
        for i, idx in enumerate(tflite_top5_indices):
            breed = self.index_to_breed[idx]
            conf = tflite_preds[idx]
            print(f"     {i+1}. {breed}: {conf:.6f}")
        
        # Check if predictions are too uniform (potential issue)
        if h5_std < 0.01:
            print(f"⚠️ WARNING: H5 predictions are very uniform (std={h5_std:.6f})")
        if tflite_std < 0.01:
            print(f"⚠️ WARNING: TFLite predictions are very uniform (std={tflite_std:.6f})")
        
        # Check if karelian_bobtail is always winning
        karelian_idx = self.class_indices['karelian_bobtail']
        h5_karelian_conf = h5_preds[karelian_idx]
        tflite_karelian_conf = tflite_preds[karelian_idx]
        
        print(f"\n🔍 Karelian Bobtail Analysis (index {karelian_idx}):")
        print(f"   H5 confidence: {h5_karelian_conf:.6f}")
        print(f"   TFLite confidence: {tflite_karelian_conf:.6f}")
        
        if h5_karelian_conf == h5_max and tflite_karelian_conf == tflite_max:
            print(f"❌ ISSUE: Karelian Bobtail is highest for both models - potential preprocessing problem!")
    
    def run_comparison(self):
        """Run comparison on all test images"""
        
        print("\n🚀 Starting Model Comparison Test")
        print("=" * 50)
        
        # Load models
        if not self.load_models():
            return False
        
        # Get test images
        image_extensions = {'.jpg', '.jpeg', '.png'}
        test_images = [
            f for f in self.test_images_dir.iterdir() 
            if f.suffix.lower() in image_extensions
        ]
        
        if not test_images:
            print("❌ No test images found!")
            return False
        
        print(f"\n🧪 Found {len(test_images)} test images")
        
        # Analyze test images first
        self.analyze_test_images()
        
        # Test each image
        for image_path in sorted(test_images):
            result = self.test_single_image(image_path)
            if result:
                self.comparison_results.append(result)
        
        # Generate summary report
        self.generate_report()
        
        return True
    
    def generate_report(self):
        """Generate comprehensive comparison report"""
        
        if not self.comparison_results:
            print("❌ No results to report")
            return
        
        print("\n" + "=" * 60)
        print("📊 COMPREHENSIVE MODEL COMPARISON REPORT")
        print("=" * 60)
        
        # Overall statistics
        total_tests = len(self.comparison_results)
        same_predictions = sum(1 for r in self.comparison_results if r['comparison']['same_prediction'])
        accuracy_agreement = same_predictions / total_tests * 100
        
        # Performance statistics
        avg_h5_time = np.mean([r['h5']['processing_time'] for r in self.comparison_results])
        avg_tflite_time = np.mean([r['tflite']['processing_time'] for r in self.comparison_results])
        avg_speed_ratio = np.mean([r['comparison']['speed_ratio'] for r in self.comparison_results])
        
        # Confidence statistics
        avg_confidence_diff = np.mean([r['comparison']['confidence_difference'] for r in self.comparison_results])
        max_confidence_diff = max([r['comparison']['confidence_difference'] for r in self.comparison_results])
        
        avg_h5_confidence = np.mean([r['h5']['confidence'] for r in self.comparison_results])
        avg_tflite_confidence = np.mean([r['tflite']['confidence'] for r in self.comparison_results])
        
        print(f"\n🔍 OVERALL COMPARISON:")
        print(f"  📸 Total Images Tested: {total_tests}")
        print(f"  🎯 Prediction Agreement: {same_predictions}/{total_tests} ({accuracy_agreement:.1f}%)")
        print(f"  📊 Average Confidence Difference: {avg_confidence_diff:.3f}")
        print(f"  📈 Maximum Confidence Difference: {max_confidence_diff:.3f}")
        
        print(f"\n⚡ PERFORMANCE COMPARISON:")
        print(f"  🧠 H5 Model Average Time: {avg_h5_time:.3f}s")
        print(f"  📱 TFLite Average Time: {avg_tflite_time:.3f}s")
        print(f"  🚀 Speed Improvement: {avg_speed_ratio:.1f}x faster")
        
        print(f"\n🎯 CONFIDENCE ANALYSIS:")
        print(f"  🧠 H5 Average Confidence: {avg_h5_confidence:.3f}")
        print(f"  📱 TFLite Average Confidence: {avg_tflite_confidence:.3f}")
        print(f"  📊 Confidence Difference: {abs(avg_h5_confidence - avg_tflite_confidence):.3f}")
        
        # Detailed results
        print(f"\n📋 DETAILED RESULTS:")
        print("-" * 60)
        
        for i, result in enumerate(self.comparison_results, 1):
            print(f"\n{i}. {result['image_name']}")
            print(f"   🧠 H5:     {result['h5']['predicted_breed']:20s} ({result['h5']['confidence']:.3f})")
            print(f"   📱 TFLite: {result['tflite']['predicted_breed']:20s} ({result['tflite']['confidence']:.3f})")
            
            match_symbol = "✅ MATCH" if result['comparison']['same_prediction'] else "❌ DIFFERENT"
            print(f"   🔍 Result: {match_symbol}")
            print(f"   ⚡ Speed:  {result['comparison']['speed_ratio']:.1f}x faster (TFLite)")
            print(f"   📊 Conf Δ: {result['comparison']['confidence_difference']:.3f}")
        
        # Disagreement analysis
        disagreements = [r for r in self.comparison_results if not r['comparison']['same_prediction']]
        if disagreements:
            print(f"\n❌ DISAGREEMENT ANALYSIS:")
            print("-" * 40)
            for result in disagreements:
                print(f"\n📸 {result['image_name']}:")
                print(f"  🧠 H5:     {result['h5']['predicted_breed']} ({result['h5']['confidence']:.3f})")
                print(f"  📱 TFLite: {result['tflite']['predicted_breed']} ({result['tflite']['confidence']:.3f})")
                
                # Show top 3 for both models
                print(f"  🥇 H5 Top 3:")
                for j, pred in enumerate(result['h5']['top_3']):
                    print(f"     {j+1}. {pred['breed']} ({pred['confidence']:.3f})")
                
                print(f"  🥇 TFLite Top 3:")
                for j, pred in enumerate(result['tflite']['top_3']):
                    print(f"     {j+1}. {pred['breed']} ({pred['confidence']:.3f})")
        
        # Save results to file
        self.save_results()
        
        print(f"\n🎯 SUMMARY:")
        if accuracy_agreement >= 90:
            print(f"✅ EXCELLENT: Models agree on {accuracy_agreement:.1f}% of predictions")
        elif accuracy_agreement >= 80:
            print(f"✅ GOOD: Models agree on {accuracy_agreement:.1f}% of predictions")
        elif accuracy_agreement >= 70:
            print(f"⚠️ FAIR: Models agree on {accuracy_agreement:.1f}% of predictions")
        else:
            print(f"❌ POOR: Models only agree on {accuracy_agreement:.1f}% of predictions")
        
        print(f"⚡ TFLite is {avg_speed_ratio:.1f}x faster on average")
        print(f"📊 Average confidence difference: {avg_confidence_diff:.3f}")
        
        print("\n" + "=" * 60)
    
    def save_results(self):
        """Save detailed results to JSON file"""
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        results_file = self.script_dir / f"model_comparison_{timestamp}.json"
        
        # Prepare data for JSON serialization
        json_results = {
            'timestamp': timestamp,
            'test_info': {
                'h5_model_path': str(self.h5_model_path),
                'tflite_model_path': str(self.tflite_model_path),
                'total_images': len(self.comparison_results),
                'input_size': self.input_size
            },
            'summary': {
                'prediction_agreement_rate': sum(1 for r in self.comparison_results if r['comparison']['same_prediction']) / len(self.comparison_results),
                'avg_h5_processing_time': float(np.mean([r['h5']['processing_time'] for r in self.comparison_results])),
                'avg_tflite_processing_time': float(np.mean([r['tflite']['processing_time'] for r in self.comparison_results])),
                'avg_speed_improvement': float(np.mean([r['comparison']['speed_ratio'] for r in self.comparison_results])),
                'avg_confidence_difference': float(np.mean([r['comparison']['confidence_difference'] for r in self.comparison_results]))
            },
            'detailed_results': self.comparison_results
        }
        
        with open(results_file, 'w') as f:
            json.dump(json_results, f, indent=2)
        
        print(f"💾 Detailed results saved to: {results_file}")

def main():
    """Main function to run the comparison"""
    
    print("🐱 MeowAI Model Comparison Test")
    print("Testing H5 vs TFLite model accuracy and performance")
    print("=" * 60)
    
    comparator = ModelComparator()
    
    try:
        success = comparator.run_comparison()
        
        if success:
            print("\n✅ Model comparison completed successfully!")
        else:
            print("\n❌ Model comparison failed!")
            
    except KeyboardInterrupt:
        print("\n\n⏹️ Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")

if __name__ == "__main__":
    main()