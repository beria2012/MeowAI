# LiteRT Migration Guide for MeowAI

## Overview
LiteRT (ai-edge-litert) is Google's next-generation runtime that replaces TensorFlow Lite. It supports modern opcodes including FULLY_CONNECTED version 12.

## Migration Steps

### 1. Update Dependencies

Replace TensorFlow Lite dependencies in `android/app/build.gradle.kts`:

```kotlin
dependencies {
    // Remove old TensorFlow Lite dependencies
    // implementation("org.tensorflow:tensorflow-lite:2.16.1")
    // implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
    // implementation("org.tensorflow:tensorflow-lite-gpu:2.16.1")
    
    // Add LiteRT dependencies
    implementation("com.google.ai.edge.litert:litert:0.1.0")
    implementation("com.google.ai.edge.litert:litert-support:0.1.0")
}
```

### 2. Update Native Plugin

Modify `NativeTFLitePlugin.kt` to use LiteRT APIs:

```kotlin
// Replace TensorFlow Lite imports
// import org.tensorflow.lite.Interpreter

// Add LiteRT imports
import ai.edge.litert.Interpreter
import ai.edge.litert.InterpreterApi
```

### 3. Code Changes Required

#### Minimal Changes:
- Import statements
- Some API method names

#### API Differences:
- `Interpreter` constructor may have slightly different parameters
- Some options classes may have different names
- Error messages may be different

### 4. Benefits of LiteRT

- ✅ Supports modern opcodes (FULLY_CONNECTED v12+)
- ✅ Better GPU acceleration
- ✅ Improved performance
- ✅ Native hardware buffer support
- ✅ True async execution

### 5. Migration Script

Use the provided migration script to automate the process:

```bash
cd tools
python migrate_to_litert.py
```

## Compatibility Matrix

| Feature | TensorFlow Lite 2.16.1 | LiteRT 0.1.0 |
|---------|------------------------|---------------|
| FULLY_CONNECTED v12 | ❌ | ✅ |
| Modern Opcodes | ❌ | ✅ |
| GPU Acceleration | ⚠️ Limited | ✅ Enhanced |
| Your Model | ❌ | ✅ |

## Risk Assessment

### Low Risk:
- API is very similar to TensorFlow Lite
- Google's official replacement
- Minimal code changes required

### Considerations:
- Newer library (less battle-tested)
- Dependency size might be different
- Some edge cases might behave differently

## Recommendation

LiteRT migration is the **best long-term solution** as it:
1. Solves your immediate compatibility issue
2. Future-proofs your app
3. Provides better performance
4. Is Google's official direction