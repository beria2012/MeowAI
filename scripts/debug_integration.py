#!/usr/bin/env python3
"""
Debug Model Integration Test
===========================
Quick test to verify model and breed data integration
"""

import json
import os
from pathlib import Path

def debug_model_integration():
    """Debug the current model integration issues"""
    
    print("🐞 Debug: Model Integration")
    print("=" * 40)
    
    # Test 1: Check enhanced breed data format
    breed_data_path = Path("/Users/oleksandr/Projects/MeowAI/MeowAI/assets/data/enhanced_breeds.json")
    
    if breed_data_path.exists():
        with open(breed_data_path, 'r') as f:
            breed_data = json.load(f)
        
        print(f"✅ Breed data found: {len(breed_data)} breeds")
        
        # Check first breed structure
        if len(breed_data) > 0:
            first_breed = breed_data[0]
            print(f"📊 First breed structure:")
            for key in first_breed.keys():
                print(f"  {key}: {type(first_breed[key])}")
            
            # Check for required Flutter fields
            required_fields = ['life_span', 'image_url', 'is_hypoallergenic', 'is_rare', 'energy_level', 'social_needs', 'grooming_needs']
            missing_fields = [f for f in required_fields if f not in first_breed]
            
            if not missing_fields:
                print("✅ All required fields present")
            else:
                print(f"❌ Missing fields: {missing_fields}")
        
        # Check ML indices
        ml_indices = [breed['ml_index'] for breed in breed_data if 'ml_index' in breed]
        print(f"📊 ML indices: {len(ml_indices)} breeds have ml_index")
        print(f"📊 Index range: {min(ml_indices)} to {max(ml_indices)}")
        
    else:
        print("❌ Enhanced breed data not found")
    
    # Test 2: Check model assets
    model_files = [
        "/Users/oleksandr/Projects/MeowAI/MeowAI/assets/models/model.tflite",
        "/Users/oleksandr/Projects/MeowAI/MeowAI/assets/models/labels.txt",
        "/Users/oleksandr/Projects/MeowAI/MeowAI/assets/models/model_info.json"
    ]
    
    for model_file in model_files:
        if Path(model_file).exists():
            size = Path(model_file).stat().st_size
            print(f"✅ {Path(model_file).name}: {size/1024/1024:.1f} MB")
        else:
            print(f"❌ Missing: {Path(model_file).name}")
    
    # Test 3: Check breed images availability
    breeds_with_missing_images = []
    
    if breed_data_path.exists():
        with open(breed_data_path, 'r') as f:
            breed_data = json.load(f)
        
        for breed in breed_data[:10]:  # Check first 10
            breed_id = breed['id']
            image_path = f"/Users/oleksandr/Projects/MeowAI/MeowAI/assets/images/breeds/{breed_id}.jpg"
            png_path = f"/Users/oleksandr/Projects/MeowAI/MeowAI/assets/images/breeds/{breed_id}.png"
            
            if not Path(image_path).exists() and not Path(png_path).exists():
                breeds_with_missing_images.append(breed_id)
        
        if breeds_with_missing_images:
            print(f"⚠️ Missing images for: {breeds_with_missing_images}")
        else:
            print(f"✅ Images available for checked breeds")
    
    # Test 4: Diagnose Flutter issues
    print("\\n🔍 Flutter Integration Diagnosis:")
    print("1. CatBreed model updated to match JSON structure")
    print("2. Missing route '/encyclopedia' added to main.dart")
    print("3. Breed data service should load enhanced_breeds.json")
    
    # Test 5: Suggest fixes
    print("\\n🛠️ Suggested Fixes:")
    print("1. Restart Flutter app to reload updated breed model")
    print("2. Check that pubspec.yaml includes enhanced_breeds.json in assets")
    print("3. Verify BreedDataService is using correct asset path")
    print("4. Enable TFLite when ready for real model inference")
    
    return True

if __name__ == "__main__":
    debug_model_integration()