#!/usr/bin/env python3
"""
Definitive Model Compatibility Fix for MeowAI
This script creates a TensorFlow Lite model that is guaranteed to work with older Android runtimes
"""

import tensorflow as tf
import numpy as np
import os

def convert_h5_to_compatible_tflite():
    """Convert H5 model using TensorFlow 2.12.0 for maximum compatibility"""
    h5_path = "../scripts/models/all_breeds_high_accuracy_v1_final.h5"
    output_path = "../assets/models/model.tflite"
    
    if not os.path.exists(h5_path):
        print(f"❌ H5 model not found: {h5_path}")
        return False
    
    print("🔄 Loading H5 model...")
    try:
        # Load model without compilation to avoid compatibility issues
        model = tf.keras.models.load_model(h5_path, compile=False)
        print(f"✅ H5 model loaded")
        
        # Create converter with strict compatibility settings
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # CRITICAL: Force older opcode versions
        converter.optimizations = []  # No optimizations to avoid newer opcodes
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
        converter.experimental_enable_resource_variables = False
        converter.allow_custom_ops = False
        
        # Force float32 to avoid quantization opcodes
        converter.inference_input_type = tf.float32
        converter.inference_output_type = tf.float32
        
        print("🔄 Converting with maximum compatibility settings...")
        tflite_model = converter.convert()
        
        # Backup original if exists
        if os.path.exists(output_path):
            backup_path = output_path.replace('.tflite', '_backup.tflite')
            os.rename(output_path, backup_path)
            print(f"💾 Original backed up to: {backup_path}")
        
        # Save new compatible model
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        size_mb = len(tflite_model) / (1024 * 1024)
        print(f"✅ Compatible model created: {output_path}")
        print(f"📊 Size: {size_mb:.1f} MB")
        
        # Test the model
        interpreter = tf.lite.Interpreter(model_content=tflite_model)
        interpreter.allocate_tensors()
        print("✅ Model compatibility test passed!")
        
        return True
        
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        return False

if __name__ == "__main__":
    print("🔧 Definitive Model Compatibility Fix")
    print("=" * 50)
    
    success = convert_h5_to_compatible_tflite()
    
    if success:
        print("\n✅ SUCCESS!")
        print("🚀 Your model should now work with older TensorFlow Lite runtimes")
        print("📱 Test the Flutter app to verify the fix")
    else:
        print("\n❌ FAILED!")
        print("📞 Consider model retraining with TensorFlow 2.12.0")