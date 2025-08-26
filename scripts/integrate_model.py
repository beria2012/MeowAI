#!/usr/bin/env python3
"""
Model Integration Script
========================
Converts H5 model to TensorFlow Lite and prepares assets for Flutter integration.
"""

import os
import json
import tensorflow as tf
from pathlib import Path

def convert_h5_to_tflite():
    """Convert H5 model to TensorFlow Lite format"""
    
    print("🔄 Converting H5 model to TensorFlow Lite...")
    
    # Paths
    h5_path = "/Users/oleksandr/Projects/MeowAI/MeowAI/scripts/training/all_breeds_high_accuracy_v1_final.h5"
    tflite_path = "/Users/oleksandr/Projects/MeowAI/MeowAI/assets/models/model.tflite"
    
    # Ensure assets/models directory exists
    Path("/Users/oleksandr/Projects/MeowAI/MeowAI/assets/models").mkdir(parents=True, exist_ok=True)
    
    try:
        # Load the H5 model
        print(f"📂 Loading model from: {h5_path}")
        model = tf.keras.models.load_model(h5_path)
        
        print("📊 Model summary:")
        model.summary()
        
        # Convert to TensorFlow Lite
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # Optimization settings for mobile
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        
        # Set supported ops (if needed)
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS
        ]
        
        # Convert
        tflite_model = converter.convert()
        
        # Save TFLite model
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        
        print(f"✅ TFLite model saved to: {tflite_path}")
        print(f"📦 Model size: {len(tflite_model) / 1024 / 1024:.2f} MB")
        
        return True
        
    except Exception as e:
        print(f"❌ Error converting model: {e}")
        return False

def create_labels_file():
    """Create labels.txt from class_indices.json"""
    
    print("📋 Creating labels file...")
    
    class_indices_path = "/Users/oleksandr/Projects/MeowAI/MeowAI/scripts/training/class_indices.json"
    labels_path = "/Users/oleksandr/Projects/MeowAI/MeowAI/assets/models/labels.txt"
    
    try:
        # Load class indices
        with open(class_indices_path, 'r') as f:
            class_indices = json.load(f)
        
        print(f"📊 Found {len(class_indices)} cat breeds")
        
        # Create labels list (sorted by index)
        labels = [''] * len(class_indices)
        for breed_name, index in class_indices.items():
            labels[index] = breed_name
        
        # Write labels file
        with open(labels_path, 'w') as f:
            for label in labels:
                f.write(f"{label}\n")
        
        print(f"✅ Labels file saved to: {labels_path}")
        print(f"📋 Breeds included: {', '.join(labels[:5])}...")
        
        return labels
        
    except Exception as e:
        print(f"❌ Error creating labels file: {e}")
        return None

def create_model_info():
    """Create model_info.json with model metadata"""
    
    print("📄 Creating model info file...")
    
    model_info_path = "/Users/oleksandr/Projects/MeowAI/MeowAI/assets/models/model_info.json"
    
    # Load class indices to get breed count
    class_indices_path = "/Users/oleksandr/Projects/MeowAI/MeowAI/scripts/training/class_indices.json"
    
    try:
        with open(class_indices_path, 'r') as f:
            class_indices = json.load(f)
        
        model_info = {
            "model_name": "all_breeds_high_accuracy_v1",
            "version": "1.0",
            "architecture": "EfficientNetV2-B3",
            "input_size": 384,
            "num_classes": len(class_indices),
            "breeds": list(class_indices.keys()),
            "created_date": "2025-08-25",
            "accuracy_target": "60-75%",
            "description": "High accuracy cat breed classifier trained on all supported breeds",
            "preprocessing": {
                "normalization": "0-1 scale",
                "resize": [384, 384],
                "channels": 3
            }
        }
        
        with open(model_info_path, 'w') as f:
            json.dump(model_info, f, indent=2)
        
        print(f"✅ Model info saved to: {model_info_path}")
        
        return model_info
        
    except Exception as e:
        print(f"❌ Error creating model info: {e}")
        return None

def main():
    """Main integration function"""
    
    print("🎯 MeowAI Model Integration")
    print("=" * 40)
    
    # Step 1: Convert H5 to TFLite
    if not convert_h5_to_tflite():
        print("❌ Model conversion failed!")
        return False
    
    # Step 2: Create labels file
    labels = create_labels_file()
    if labels is None:
        print("❌ Labels creation failed!")
        return False
    
    # Step 3: Create model info
    model_info = create_model_info()
    if model_info is None:
        print("❌ Model info creation failed!")
        return False
    
    print("\n🎉 Model Integration Complete!")
    print("=" * 40)
    print(f"✅ Model: assets/models/model.tflite")
    print(f"✅ Labels: assets/models/labels.txt ({len(labels)} breeds)")
    print(f"✅ Info: assets/models/model_info.json")
    print("\n📱 Ready for Flutter integration!")
    
    return True

if __name__ == "__main__":
    main()