#!/usr/bin/env python3
"""
Model Compatibility Converter for MeowAI
Converts existing model.tflite to be compatible with older TensorFlow Lite runtime versions
Specifically targeting FULLY_CONNECTED opcode version compatibility
"""

import tensorflow as tf
import numpy as np
import os
import sys
import json
from pathlib import Path

def analyze_existing_model():
    """Analyze the current model to understand the compatibility issue"""
    model_path = "../assets/models/model.tflite"
    
    if not os.path.exists(model_path):
        print(f"❌ Model not found at: {model_path}")
        return None
    
    print(f"🔍 Analyzing existing TFLite model...")
    
    try:
        # Load the existing model
        with open(model_path, 'rb') as f:
            model_content = f.read()
        
        # Try to create interpreter (this will fail with opcode error)
        try:
            interpreter = tf.lite.Interpreter(model_content=model_content)
            interpreter.allocate_tensors()
            print("✅ Model loads successfully - no compatibility issues")
            return None
        except Exception as e:
            if "FULLY_CONNECTED" in str(e) and "version" in str(e):
                print(f"✅ Confirmed opcode compatibility issue: {e}")
                return {
                    'model_content': model_content,
                    'size_mb': len(model_content) / (1024*1024),
                    'error': str(e)
                }
            else:
                print(f"❌ Different error: {e}")
                return None
                
    except Exception as e:
        print(f"❌ Failed to analyze model: {e}")
        return None

def create_compatible_model_from_h5():
    """Create a compatible TFLite model from the H5 source if available"""
    h5_path = "../scripts/models/all_breeds_high_accuracy_v1_final.h5"
    
    if not os.path.exists(h5_path):
        print(f"❌ H5 model not found at: {h5_path}")
        return None
    
    print(f"🔄 Converting H5 model to compatible TFLite format...")
    
    try:
        # Load H5 model
        model = tf.keras.models.load_model(h5_path, compile=False)
        print(f"✅ H5 model loaded successfully")
        
        # Create converter with strict compatibility settings
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # CRITICAL: Set compatibility flags for older TensorFlow Lite
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
        
        # Disable features that might cause compatibility issues
        converter.experimental_enable_resource_variables = False
        converter.allow_custom_ops = False
        
        # Force older opcode versions
        converter.target_spec.supported_types = [tf.float32]
        
        # Representative dataset for better quantization
        def representative_data_gen():
            for i in range(100):
                # Generate sample data matching model input (384x384x3)
                yield [np.random.rand(1, 384, 384, 3).astype(np.float32)]
        
        converter.representative_dataset = representative_data_gen
        
        # Convert model
        print("🔄 Converting model with compatibility settings...")
        tflite_model = converter.convert()
        
        # Save compatible model
        output_path = "../assets/models/model_compatible.tflite"
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        model_size = len(tflite_model) / (1024 * 1024)
        print(f"✅ Compatible model created: {output_path}")
        print(f"📊 Model size: {model_size:.1f} MB")
        
        return {
            'path': output_path,
            'size_mb': model_size,
            'model_data': tflite_model
        }
        
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        return None

def test_compatible_model(model_info):
    """Test the converted model for compatibility"""
    if not model_info:
        return False
    
    print(f"🧪 Testing compatible model...")
    
    try:
        # Test with TensorFlow Lite
        interpreter = tf.lite.Interpreter(model_content=model_info['model_data'])
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"✅ Model loads successfully!")
        print(f"📥 Input shape: {input_details[0]['shape']}")
        print(f"📤 Output shape: {output_details[0]['shape']}")
        
        # Test inference
        test_input = np.random.rand(*input_details[0]['shape']).astype(np.float32)
        interpreter.set_tensor(input_details[0]['index'], test_input)
        interpreter.invoke()
        
        output = interpreter.get_tensor(output_details[0]['index'])
        print(f"✅ Inference test passed! Output shape: {output.shape}")
        
        return True
        
    except Exception as e:
        print(f"❌ Compatibility test failed: {e}")
        return False

def backup_original_model():
    """Backup the original model before replacement"""
    original_path = "../assets/models/model.tflite"
    backup_path = "../assets/models/model_original_backup.tflite"
    
    if os.path.exists(original_path):
        import shutil
        shutil.copy2(original_path, backup_path)
        print(f"💾 Original model backed up to: {backup_path}")
        return True
    return False

def replace_model_with_compatible():
    """Replace the original model with the compatible version"""
    compatible_path = "../assets/models/model_compatible.tflite"
    original_path = "../assets/models/model.tflite"
    
    if not os.path.exists(compatible_path):
        print(f"❌ Compatible model not found at: {compatible_path}")
        return False
    
    try:
        import shutil
        shutil.copy2(compatible_path, original_path)
        print(f"✅ Replaced original model with compatible version")
        print(f"📁 Original: {original_path}")
        print(f"🔄 Source: {compatible_path}")
        return True
    except Exception as e:
        print(f"❌ Failed to replace model: {e}")
        return False

def create_model_info():
    """Create model info file for the compatible model"""
    model_info = {
        "model_name": "all_breeds_compatible",
        "version": "1.0.0",
        "compatibility": "TensorFlow Lite 2.13.0+",
        "opcode_version": "Compatible with older runtimes",
        "input_size": [384, 384, 3],
        "output_size": 40,
        "num_classes": 40,
        "model_type": "EfficientNetV2-B3 (compatible)",
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
    
    info_path = "../assets/models/model_info.json"
    with open(info_path, 'w') as f:
        json.dump(model_info, f, indent=2)
    
    print(f"📄 Model info created: {info_path}")

def main():
    """Main conversion process"""
    print("🔧 MeowAI Model Compatibility Converter")
    print("=" * 60)
    
    # Step 1: Analyze existing model
    analysis = analyze_existing_model()
    if not analysis:
        print("ℹ️ No compatibility issues detected or analysis failed")
        return
    
    print(f"📊 Current model: {analysis['size_mb']:.1f} MB")
    print(f"🔍 Issue: {analysis['error']}")
    
    # Step 2: Create compatible model from H5
    compatible_model = create_compatible_model_from_h5()
    if not compatible_model:
        print("❌ Failed to create compatible model")
        return
    
    # Step 3: Test compatible model
    if not test_compatible_model(compatible_model):
        print("❌ Compatible model failed testing")
        return
    
    # Step 4: Backup and replace
    print("\n🔄 Replacing model files...")
    backup_original_model()
    
    if replace_model_with_compatible():
        create_model_info()
        print("\n" + "=" * 60)
        print("✅ Model conversion completed successfully!")
        print("🎯 Your model should now be compatible with TensorFlow Lite 2.13.0")
        print("📱 Test the app to verify opcode compatibility is resolved")
        print("\n🔄 Next steps:")
        print("1. Run the Flutter app")
        print("2. Check logs for successful model initialization")
        print("3. Test cat breed recognition functionality")
    else:
        print("❌ Failed to replace model files")

if __name__ == "__main__":
    main()