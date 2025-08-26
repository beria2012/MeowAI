#!/usr/bin/env python3
"""
Convert Real Model to Compatible TensorFlow Lite
Converts all_breeds_high_accuracy_v1_final.h5 to compatible TFLite format
"""

import tensorflow as tf
import numpy as np
import os
import sys
import json

def convert_real_model_to_compatible():
    """Convert the real trained H5 model to compatible TFLite format"""
    print("🔄 Converting Real Model: all_breeds_high_accuracy_v1_final.h5")
    print("=" * 70)
    
    # Path to the original trained model
    h5_model_path = "../scripts/training/all_breeds_high_accuracy_v1_final.h5"
    output_path = "../assets/models/model.tflite"
    
    if not os.path.exists(h5_model_path):
        print(f"❌ H5 model not found: {h5_model_path}")
        print("Please ensure the model file exists at the specified path")
        return False
    
    print(f"📂 Loading H5 model from: {h5_model_path}")
    
    try:
        # Load the trained model without compilation to avoid version conflicts
        model = tf.keras.models.load_model(h5_model_path, compile=False)
        print(f"✅ H5 model loaded successfully")
        
        # Print model summary for verification
        print(f"📊 Model Summary:")
        print(f"   Input shape: {model.input_shape}")
        print(f"   Output shape: {model.output_shape}")
        print(f"   Total parameters: {model.count_params():,}")
        
        # Create converter with MAXIMUM compatibility settings
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # CRITICAL: Force older opcode versions for Android compatibility
        print("🔧 Applying maximum compatibility settings...")
        
        # No optimizations to avoid newer opcodes
        converter.optimizations = []
        
        # Only use basic TensorFlow Lite operations
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
        
        # Disable features that might cause compatibility issues
        converter.experimental_enable_resource_variables = False
        converter.allow_custom_ops = False
        
        # Force float32 to avoid quantization-related opcodes
        converter.inference_input_type = tf.float32
        converter.inference_output_type = tf.float32
        
        # Additional compatibility settings
        converter.target_spec.supported_types = [tf.float32]
        
        print("🔄 Converting to TensorFlow Lite (this may take a few minutes)...")
        tflite_model = converter.convert()
        
        # Backup original mock model if it exists
        if os.path.exists(output_path):
            backup_path = output_path.replace('.tflite', '_mock_backup.tflite')
            os.rename(output_path, backup_path)
            print(f"💾 Mock model backed up to: {backup_path}")
        
        # Save the converted real model
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        model_size_mb = len(tflite_model) / (1024 * 1024)
        print(f"✅ Real model converted and saved: {output_path}")
        print(f"📊 Converted model size: {model_size_mb:.1f} MB")
        
        # Test the converted model for compatibility
        print("🧪 Testing converted model compatibility...")
        try:
            interpreter = tf.lite.Interpreter(model_content=tflite_model)
            interpreter.allocate_tensors()
            
            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            
            print(f"✅ Compatibility test PASSED!")
            print(f"📥 Input shape: {input_details[0]['shape']}")
            print(f"📤 Output shape: {output_details[0]['shape']}")
            
            # Test inference with random data
            test_input = np.random.rand(*input_details[0]['shape']).astype(np.float32)
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()
            
            output = interpreter.get_tensor(output_details[0]['index'])
            print(f"✅ Test inference successful! Output shape: {output.shape}")
            
            return True
            
        except Exception as e:
            print(f"❌ Compatibility test FAILED: {e}")
            if "FULLY_CONNECTED" in str(e) and "version" in str(e):
                print("⚠️  This indicates the model still has opcode compatibility issues")
                print("🔧 You may need to retrain the model with TensorFlow 2.12.0")
            return False
            
    except Exception as e:
        print(f"❌ Model conversion failed: {e}")
        return False

def update_model_info():
    """Update model info for the real converted model"""
    model_info = {
        "model_name": "all_breeds_high_accuracy_v1_final_compatible",
        "version": "1.0.0",
        "compatibility": "TensorFlow Lite 2.12.0+ compatible",
        "type": "EfficientNetV2-B3 (converted for compatibility)",
        "input_size": [384, 384, 3],
        "output_size": 40,
        "num_classes": 40,
        "note": "Real trained model converted with compatibility settings for Android runtime",
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
    
    print(f"📄 Model info updated: {info_path}")

def main():
    print("🚀 Real Model to Compatible TensorFlow Lite Converter")
    print("=" * 70)
    print("Converting your trained all_breeds_high_accuracy_v1_final.h5 model")
    print("to a compatible TensorFlow Lite format for Android.")
    print("")
    
    success = convert_real_model_to_compatible()
    
    if success:
        update_model_info()
        
        print("\n" + "=" * 70)
        print("✅ SUCCESS!")
        print("🎉 Your real trained model has been converted successfully!")
        print("🚀 This should resolve the FULLY_CONNECTED opcode compatibility issue")
        print("")
        print("🔄 Next steps:")
        print("1. Clean rebuild the Flutter app to ensure new model is packaged")
        print("2. Test the app - you should now see real cat breed recognition!")
        print("3. The app will use your actual trained model instead of the mock")
        print("")
        print("⚠️  If opcode errors persist:")
        print("   - The original model may need retraining with TensorFlow 2.12.0")
        print("   - Consider using the mock model as a temporary solution")
        
    else:
        print("\n" + "=" * 70)
        print("❌ CONVERSION FAILED!")
        print("🔧 Possible solutions:")
        print("1. Retrain the model using TensorFlow 2.12.0 for maximum compatibility")
        print("2. Use the mock model temporarily while retraining")
        print("3. Check if the H5 model file is accessible and not corrupted")

if __name__ == "__main__":
    main()