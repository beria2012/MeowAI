#!/usr/bin/env python3
"""
Mock Compatible Model Creator for MeowAI
Creates a simple TensorFlow Lite model with older opcodes for immediate testing
This allows the app to work while the real model is being retrained
"""

import tensorflow as tf
import numpy as np
import os
import json

def create_mock_compatible_model():
    """Create a simple compatible TensorFlow Lite model for testing"""
    print("🔄 Creating mock compatible TensorFlow Lite model...")
    
    # Create a simple model with same input/output dimensions as original
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(384, 384, 3)),
        tf.keras.layers.Conv2D(32, 3, activation='relu', padding='same'),
        tf.keras.layers.MaxPooling2D(2),
        tf.keras.layers.Conv2D(64, 3, activation='relu', padding='same'),
        tf.keras.layers.MaxPooling2D(2),
        tf.keras.layers.Conv2D(128, 3, activation='relu', padding='same'),
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dense(256, activation='relu'),
        tf.keras.layers.Dropout(0.5),
        tf.keras.layers.Dense(40, activation='softmax')  # 40 cat breeds
    ])
    
    # Compile model
    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    print("✅ Mock model architecture created")
    
    # Create converter with strict compatibility
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # CRITICAL: Use minimal optimizations for maximum compatibility
    converter.optimizations = []  # No optimizations
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
    converter.experimental_enable_resource_variables = False
    converter.allow_custom_ops = False
    
    # Force float32 for compatibility
    converter.inference_input_type = tf.float32
    converter.inference_output_type = tf.float32
    
    print("🔄 Converting to TensorFlow Lite...")
    tflite_model = converter.convert()
    
    # Test the model
    interpreter = tf.lite.Interpreter(model_content=tflite_model)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"✅ Mock model created successfully")
    print(f"📥 Input shape: {input_details[0]['shape']}")
    print(f"📤 Output shape: {output_details[0]['shape']}")
    
    # Test inference
    test_input = np.random.rand(*input_details[0]['shape']).astype(np.float32)
    interpreter.set_tensor(input_details[0]['index'], test_input)
    interpreter.invoke()
    
    output = interpreter.get_tensor(output_details[0]['index'])
    print(f"✅ Test inference successful")
    
    return tflite_model

def save_compatible_model(tflite_model):
    """Save the compatible model"""
    # Backup original model
    original_path = "../assets/models/model.tflite"
    backup_path = "../assets/models/model_original_opcode_issue.tflite"
    
    if os.path.exists(original_path):
        os.rename(original_path, backup_path)
        print(f"💾 Original model backed up to: {backup_path}")
    
    # Save new compatible model
    with open(original_path, 'wb') as f:
        f.write(tflite_model)
    
    size_mb = len(tflite_model) / (1024 * 1024)
    print(f"✅ Compatible model saved: {original_path}")
    print(f"📊 Size: {size_mb:.1f} MB")

def create_model_info():
    """Create model info for the mock model"""
    model_info = {
        "model_name": "mock_compatible_model",
        "version": "1.0.0",
        "compatibility": "TensorFlow Lite 2.12.0+ (older opcodes)",
        "type": "Mock model for testing",
        "input_size": [384, 384, 3],
        "output_size": 40,
        "num_classes": 40,
        "note": "This is a mock model for testing compatibility. Replace with retrained model for production.",
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
    print("🔧 Mock Compatible Model Creator for MeowAI")
    print("=" * 60)
    print("This creates a simple compatible model for immediate testing.")
    print("⚠️  Note: This is NOT your trained model - it's for compatibility testing only!")
    print("🎯 You'll need to retrain your actual model with TensorFlow 2.12.0 for production use.")
    print("")
    
    try:
        # Create mock model
        tflite_model = create_mock_compatible_model()
        
        # Save model
        save_compatible_model(tflite_model)
        
        # Create info
        create_model_info()
        
        print("\n" + "=" * 60)
        print("✅ SUCCESS!")
        print("🚀 Mock compatible model created and installed")
        print("📱 Test the Flutter app - ML inference should now work!")
        print("")
        print("⚠️  IMPORTANT:")
        print("   - This is a MOCK model that gives random predictions")
        print("   - For real cat breed recognition, retrain your model with TensorFlow 2.12.0")
        print("   - The app will now show that ML is working, but predictions will be random")
        print("")
        print("🔄 Next steps:")
        print("   1. Test the app to verify opcode compatibility is resolved")
        print("   2. Retrain your actual model using TensorFlow 2.12.0")
        print("   3. Replace the mock model with your real trained model")
        
    except Exception as e:
        print(f"\n❌ FAILED: {e}")
        print("📞 Manual intervention required")

if __name__ == "__main__":
    main()