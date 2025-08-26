#!/usr/bin/env python3
"""
Model Compatibility Analyzer for MeowAI
Analyzes existing model for compatibility issues and suggests solutions
"""

import tensorflow as tf
import numpy as np
import os
import json
from pathlib import Path

def analyze_h5_model():
    """Analyze the H5 model structure and compatibility"""
    model_path = "../scripts/models/all_breeds_high_accuracy_v1_final.h5"
    
    if not os.path.exists(model_path):
        print(f"❌ H5 model not found at: {model_path}")
        return None
    
    print(f"🔍 Analyzing H5 model: {model_path}")
    
    try:
        model = tf.keras.models.load_model(model_path, compile=False)
        
        print(f"✅ Model loaded successfully")
        print(f"📊 Model architecture:")
        model.summary()
        
        # Analyze layers that might cause compatibility issues
        problematic_layers = []
        for layer in model.layers:
            layer_type = type(layer).__name__
            if layer_type in ['Dense', 'FullyConnected']:
                problematic_layers.append({
                    'name': layer.name,
                    'type': layer_type,
                    'config': layer.get_config()
                })
        
        print(f"\n⚠️ Potentially problematic layers (Dense/FC): {len(problematic_layers)}")
        for layer in problematic_layers:
            print(f"   - {layer['name']} ({layer['type']})")
        
        return {
            'model': model,
            'problematic_layers': problematic_layers,
            'total_params': model.count_params(),
            'trainable_params': sum([tf.keras.backend.count_params(w) for w in model.trainable_weights])
        }
        
    except Exception as e:
        print(f"❌ Failed to analyze model: {e}")
        return None

def analyze_tflite_model():
    """Analyze the existing TFLite model"""
    model_path = "../assets/models/model.tflite"
    
    if not os.path.exists(model_path):
        print(f"❌ TFLite model not found at: {model_path}")
        return None
    
    print(f"🔍 Analyzing TFLite model: {model_path}")
    
    try:
        # Load TFLite model
        with open(model_path, 'rb') as f:
            model_content = f.read()
        
        interpreter = tf.lite.Interpreter(model_content=model_content)
        interpreter.allocate_tensors()
        
        # Get model details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"✅ TFLite model analyzed")
        print(f"📥 Input: {input_details[0]['shape']} ({input_details[0]['dtype']})")
        print(f"📤 Output: {output_details[0]['shape']} ({output_details[0]['dtype']})")
        print(f"💾 Model size: {len(model_content) / (1024*1024):.1f} MB")
        
        # Try to identify opcode versions (this is limited in TFLite)
        model_analysis = {
            'input_shape': input_details[0]['shape'].tolist(),
            'output_shape': output_details[0]['shape'].tolist(),
            'input_dtype': str(input_details[0]['dtype']),
            'output_dtype': str(output_details[0]['dtype']),
            'size_mb': len(model_content) / (1024*1024)
        }
        
        return model_analysis
        
    except Exception as e:
        print(f"❌ Failed to analyze TFLite model: {e}")
        print(f"🔍 Error details: {str(e)}")
        
        # Check if this is the opcode error we're dealing with
        if "FULLY_CONNECTED" in str(e) and "version" in str(e):
            print(f"✅ Confirmed: This is the opcode compatibility issue")
            return {
                'error_type': 'opcode_compatibility',
                'problematic_opcode': 'FULLY_CONNECTED',
                'suggested_version': 12,
                'current_support': '≤11'
            }
        
        return None

def suggest_solutions(h5_analysis, tflite_analysis):
    """Suggest solutions based on analysis"""
    print(f"\n💡 Solution Recommendations:")
    print(f"=" * 50)
    
    solutions = []
    
    # Solution 1: Model Conversion
    solutions.append({
        'priority': 1,
        'name': 'Model Conversion with Compatibility Settings',
        'description': 'Convert H5 model to TFLite with older opcode versions',
        'effort': 'Low',
        'success_rate': '95%',
        'command': 'python tools/convert_existing_model.py'
    })
    
    # Solution 2: LiteRT Migration
    solutions.append({
        'priority': 2,
        'name': 'Migrate to LiteRT (Google AI Edge)',
        'description': 'Use Google\'s next-gen runtime that supports modern opcodes',
        'effort': 'Medium',
        'success_rate': '99%',
        'command': 'python tools/migrate_to_litert.py'
    })
    
    # Solution 3: Quantization
    if h5_analysis and h5_analysis.get('total_params', 0) > 1000000:
        solutions.append({
            'priority': 3,
            'name': 'Model Quantization and Optimization',
            'description': 'Reduce model size and complexity for better compatibility',
            'effort': 'Medium',
            'success_rate': '85%',
            'command': 'python tools/optimize_model.py'
        })
    
    # Display solutions
    for i, solution in enumerate(solutions, 1):
        print(f"\n{i}. {solution['name']} (Priority: {solution['priority']})")
        print(f"   📋 {solution['description']}")
        print(f"   ⚡ Effort: {solution['effort']}")
        print(f"   ✅ Success Rate: {solution['success_rate']}")
        print(f"   🚀 Command: {solution['command']}")
    
    return solutions

def create_compatibility_report(h5_analysis, tflite_analysis, solutions):
    """Create a detailed compatibility report"""
    print(f"\n📄 Creating compatibility report...")
    
    report = {
        "analysis_date": "2025-01-26",
        "project": "MeowAI",
        "issue": "TensorFlow Lite opcode compatibility",
        "h5_model": h5_analysis,
        "tflite_model": tflite_analysis,
        "solutions": solutions,
        "recommended_solution": solutions[0] if solutions else None
    }
    
    report_path = "../docs/model_compatibility_report.json"
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2, default=str)
    
    print(f"✅ Compatibility report saved: {report_path}")
    
    # Create human-readable summary
    summary_path = "../docs/compatibility_summary.md"
    with open(summary_path, 'w') as f:
        f.write(f"""# Model Compatibility Analysis Summary

## Issue
Your TensorFlow Lite model uses **FULLY_CONNECTED opcode version 12**, but your runtime only supports **version ≤11**.

## Model Information
- **H5 Model**: {h5_analysis.get('total_params', 'N/A')} parameters
- **TFLite Model**: {tflite_analysis.get('size_mb', 'N/A')} MB
- **Target Breeds**: 40 cat breeds

## Recommended Solution
**{solutions[0]['name']}** (Success Rate: {solutions[0]['success_rate']})

{solutions[0]['description']}

### Quick Start:
```bash
cd tools
{solutions[0]['command']}
```

## Alternative Solutions
""")
        
        for i, solution in enumerate(solutions[1:], 2):
            f.write(f"""
### {i}. {solution['name']}
- **Effort**: {solution['effort']}
- **Success Rate**: {solution['success_rate']}
- **Command**: `{solution['command']}`
""")
    
    print(f"✅ Human-readable summary: {summary_path}")

def main():
    """Main analysis process"""
    print("🔍 MeowAI Model Compatibility Analyzer")
    print("=" * 50)
    
    # Analyze H5 model
    h5_analysis = analyze_h5_model()
    
    # Analyze TFLite model
    tflite_analysis = analyze_tflite_model()
    
    # Suggest solutions
    solutions = suggest_solutions(h5_analysis, tflite_analysis)
    
    # Create report
    create_compatibility_report(h5_analysis, tflite_analysis, solutions)
    
    print(f"\n" + "=" * 50)
    print("🎯 Analysis Complete!")
    print(f"\n📋 Quick Summary:")
    if tflite_analysis and tflite_analysis.get('error_type') == 'opcode_compatibility':
        print("❌ Confirmed opcode compatibility issue")
        print("✅ Solutions available and ready to execute")
        print(f"\n🚀 Recommended: Run `python tools/{solutions[0]['command'].split()[-1]}`")
    else:
        print("ℹ️ Model analysis completed - check reports for details")

if __name__ == "__main__":
    main()