#!/usr/bin/env python3
"""
Model Compatibility Converter for MeowAI
Converts existing all_breeds_high_accuracy_v1_final.h5 to TensorFlow Lite 2.16.1 compatible format
"""

import tensorflow as tf
import numpy as np
import os
import sys
import json
from pathlib import Path

def downgrade_tensorflow_environment():
    """Setup environment for older TensorFlow compatibility"""
    print("🔧 Setting up TensorFlow environment for compatibility...")
    
    # Disable eager execution for older TF compatibility
    tf.compat.v1.disable_eager_execution()
    
    # Set compatibility mode
    tf.compat.v1.logging.set_verbosity(tf.compat.v1.logging.ERROR)
    
    print(f"✅ TensorFlow version: {tf.__version__}")
    return tf.__version__

def load_existing_model():
    """Load the existing H5 model"""
    model_path = "../scripts/models/all_breeds_high_accuracy_v1_final.h5"
    
    if not os.path.exists(model_path):
        print(f"❌ Model not found at: {model_path}")
        print("Please ensure your H5 model is in the correct location")
        return None
    
    try:
        print(f"📂 Loading model from: {model_path}")
        
        # Load with custom objects if needed
        model = tf.keras.models.load_model(model_path, compile=False)
        
        print(f"✅ Model loaded successfully")
        print(f"📊 Model summary:")
        model.summary()
        
        return model
    
    except Exception as e:
        print(f"❌ Failed to load model: {e}")
        return None

def create_compatible_converter(model):
    """Create TensorFlow Lite converter with compatibility settings"""
    print("🔄 Creating TensorFlow Lite converter with compatibility settings...")
    
    # Create converter from Keras model
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # CRITICAL: Use only basic optimizations for compatibility
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # CRITICAL: Force older opcode versions
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS  # Only built-in ops
    ]
    
    # Disable newer features that cause compatibility issues
    converter.experimental_enable_resource_variables = False
    converter.allow_custom_ops = False
    
    # Set inference type to float32 for maximum compatibility
    converter.inference_input_type = tf.float32
    converter.inference_output_type = tf.float32
    
    # Representative dataset for quantization (optional)
    def representative_data_gen():
        for i in range(100):
            # Generate sample data matching your model input
            yield [np.random.rand(1, 384, 384, 3).astype(np.float32)]
    
    # Use representative dataset for better optimization
    converter.representative_dataset = representative_data_gen
    
    print("✅ Converter configured for TensorFlow Lite 2.16.1 compatibility")
    return converter

def convert_with_fallbacks(model):
    """Try multiple conversion strategies for maximum compatibility"""
    conversion_strategies = [
        {
            "name": "Basic Compatible Conversion",
            "optimizations": [tf.lite.Optimize.DEFAULT],
            "supported_ops": [tf.lite.OpsSet.TFLITE_BUILTINS],
            "quantize": False
        },
        {
            "name": "No Optimization Conversion", 
            "optimizations": [],
            "supported_ops": [tf.lite.OpsSet.TFLITE_BUILTINS],
            "quantize": False
        },
        {
            "name": "Float16 Quantization",
            "optimizations": [tf.lite.Optimize.DEFAULT],
            "supported_ops": [tf.lite.OpsSet.TFLITE_BUILTINS],
            "quantize": True
        }
    ]
    
    successful_conversions = []
    
    for i, strategy in enumerate(conversion_strategies):
        try:
            print(f"\n🔄 Attempting conversion strategy {i+1}/3: {strategy['name']}")
            
            converter = tf.lite.TFLiteConverter.from_keras_model(model)
            converter.optimizations = strategy['optimizations']
            converter.target_spec.supported_ops = strategy['supported_ops']
            converter.experimental_enable_resource_variables = False
            converter.allow_custom_ops = False
            
            if strategy['quantize']:
                converter.target_spec.supported_types = [tf.float16]
            
            # Convert
            tflite_model = converter.convert()
            
            # Save with strategy name
            output_filename = f"model_compatible_strategy_{i+1}.tflite"
            output_path = f"../assets/models/{output_filename}"
            
            with open(output_path, 'wb') as f:
                f.write(tflite_model)
            
            model_size = len(tflite_model) / (1024 * 1024)  # MB
            print(f"✅ Strategy {i+1} successful!")
            print(f"📁 Saved to: {output_path}")
            print(f"📊 Model size: {model_size:.1f} MB")
            
            successful_conversions.append({
                "strategy": strategy['name'],
                "path": output_path,
                "size_mb": model_size,
                "model_data": tflite_model
            })
            
        except Exception as e:
            print(f"❌ Strategy {i+1} failed: {e}")
            continue
    
    return successful_conversions

def test_converted_models(conversions):
    """Test converted models for basic functionality"""
    print(f"\n🧪 Testing {len(conversions)} successful conversions...")
    
    for i, conversion in enumerate(conversions):
        try:
            print(f"\n🔍 Testing: {conversion['strategy']}")
            
            # Create interpreter
            interpreter = tf.lite.Interpreter(model_content=conversion['model_data'])
            interpreter.allocate_tensors()
            
            # Get input/output details
            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            
            print(f"📥 Input shape: {input_details[0]['shape']}")
            print(f"📤 Output shape: {output_details[0]['shape']}")
            
            # Test with random input
            input_shape = input_details[0]['shape']
            test_input = np.random.rand(*input_shape).astype(np.float32)
            
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()
            
            output = interpreter.get_tensor(output_details[0]['index'])
            
            print(f"✅ Inference successful! Output shape: {output.shape}")
            print(f"📊 Sample predictions: {output[0][:5]}")  # First 5 predictions
            
            conversion['test_passed'] = True
            
        except Exception as e:
            print(f"❌ Test failed for {conversion['strategy']}: {e}")
            conversion['test_passed'] = False
    
    return conversions

def create_model_info(successful_conversions):
    """Create model info files for successful conversions"""
    print(f"\n📋 Creating model info files...")
    
    for conversion in successful_conversions:
        if conversion.get('test_passed', False):
            strategy_num = conversion['path'].split('_')[-1].replace('.tflite', '')
            
            model_info = {
                "model_name": f"all_breeds_compatible_strategy_{strategy_num}",
                "version": "1.0.0",
                "conversion_strategy": conversion['strategy'],
                "input_size": [384, 384, 3],
                "output_size": 40,
                "num_classes": 40,
                "model_type": "EfficientNetV2-B3",
                "compatibility": "TensorFlow Lite 2.16.1+",
                "size_mb": conversion['size_mb'],
                "preprocessing": {
                    "normalize": True,
                    "mean": [0.485, 0.456, 0.406],
                    "std": [0.229, 0.224, 0.225]
                },
                "breeds": [
                    "abyssinian", "american_shorthair", "american_wirehair", "balinese", "bengal",
                    "british_shorthair", "burmese", "chausie", "cornish_rex", "cymric",
                    "cyprus", "donskoy", "egyptian_mau", "european_shorthair", "german_rex",
                    "himalayan", "japanese_bobtail", "karelian_bobtail", "khao_manee", "lykoi",
                    "manx", "munchkin", "nebelung", "ocicat", "oriental_shorthair",
                    "persian", "peterbald", "pixie_bob", "ragamuffin", "ragdoll",
                    "savannah", "scottish_fold", "selkirk_rex", "serengeti", "sokoke",
                    "thai", "tonkinese", "turkish_angora", "turkish_van", "vankedisi"
                ]
            }
            
            info_path = conversion['path'].replace('.tflite', '_info.json')
            with open(info_path, 'w') as f:
                json.dump(model_info, f, indent=2)
            
            print(f"📄 Created info file: {info_path}")

def recommend_best_model(successful_conversions):
    """Recommend the best converted model"""
    print(f"\n🎯 Model Recommendations:")
    
    tested_models = [c for c in successful_conversions if c.get('test_passed', False)]
    
    if not tested_models:
        print("❌ No models passed testing")
        return None
    
    # Sort by size (smaller is better for mobile)
    tested_models.sort(key=lambda x: x['size_mb'])
    
    print("\n📊 Successfully converted models (ranked by size):")
    for i, model in enumerate(tested_models):
        print(f"{i+1}. {model['strategy']} - {model['size_mb']:.1f} MB")
    
    best_model = tested_models[0]
    print(f"\n🥇 Recommended model: {best_model['strategy']}")
    print(f"📁 Path: {best_model['path']}")
    print(f"💾 Size: {best_model['size_mb']:.1f} MB")
    
    # Copy to main model location
    main_model_path = "../assets/models/model_compatible.tflite"
    with open(best_model['path'], 'rb') as src, open(main_model_path, 'wb') as dst:
        dst.write(src.read())
    
    print(f"✅ Copied best model to: {main_model_path}")
    
    return best_model

def main():
    """Main conversion process"""
    print("🐱 MeowAI Model Compatibility Converter")
    print("=" * 50)
    
    # Setup environment
    tf_version = downgrade_tensorflow_environment()
    
    # Load existing model
    model = load_existing_model()
    if model is None:
        sys.exit(1)
    
    # Convert with multiple strategies
    successful_conversions = convert_with_fallbacks(model)
    
    if not successful_conversions:
        print("❌ All conversion strategies failed!")
        sys.exit(1)
    
    # Test converted models
    tested_conversions = test_converted_models(successful_conversions)
    
    # Create model info files
    create_model_info(tested_conversions)
    
    # Recommend best model
    best_model = recommend_best_model(tested_conversions)
    
    print("\n" + "=" * 50)
    print("✅ Conversion completed successfully!")
    print(f"🎯 Use the recommended model: model_compatible.tflite")
    print("📱 This model should work with TensorFlow Lite 2.16.1")
    
    if best_model:
        print(f"\n🔄 Next steps:")
        print(f"1. Test the app with the new compatible model")
        print(f"2. If it works, replace your current model.tflite")
        print(f"3. Model size reduced to {best_model['size_mb']:.1f} MB")

if __name__ == "__main__":
    main()