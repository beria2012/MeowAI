package com.meowai.meow_ai

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.InterpreterApi
import java.io.FileInputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import java.nio.MappedByteBuffer

/**
 * Native TensorFlow Lite implementation for Android
 * Uses real TensorFlow Lite Android library for ML inference
 */
class NativeTFLitePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    
    // Real TensorFlow Lite components
    private var interpreter: Interpreter? = null
    private var labels: List<String> = emptyList()
    private var isInitialized = false
    
    companion object {
        private const val CHANNEL_NAME = "native_tflite"
        private const val INPUT_SIZE = 384
        private const val OUTPUT_SIZE = 40
    }
    
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeModel" -> initializeModel(call, result)
            "runInference" -> runInference(call, result)
            "isSupported" -> isSupported(result)
            "getInfo" -> getInfo(result)
            else -> result.notImplemented()
        }
    }
    
    private fun initializeModel(call: MethodCall, result: Result) {
        try {
            val modelPath = call.argument<String>("modelPath") ?: return result.error("INVALID_ARGS", "Model path required", null)
            val labelsPath = call.argument<String>("labelsPath") ?: return result.error("INVALID_ARGS", "Labels path required", null)
            
            android.util.Log.d("NativeTFLite", "Initializing model - modelPath: $modelPath, labelsPath: $labelsPath")
            
            // Debug: List all available assets
            debugListAssets()
            
            // Load labels from assets
            android.util.Log.d("NativeTFLite", "Loading labels...")
            labels = loadLabelsFromAssets(labelsPath)
            android.util.Log.d("NativeTFLite", "Labels loaded: ${labels.size} entries")
            
            if (labels.isEmpty()) {
                android.util.Log.w("NativeTFLite", "No labels loaded - this will affect model predictions")
            }
            
            // Load actual TensorFlow Lite model with compatibility handling
            android.util.Log.d("NativeTFLite", "Loading TensorFlow Lite model...")
            val modelBuffer = loadModelFromAssets(modelPath)
            android.util.Log.d("NativeTFLite", "Model buffer loaded, creating interpreter...")
            
            // Try to create interpreter with opcode compatibility handling
            interpreter = createCompatibleInterpreter(modelBuffer)
            
            if (interpreter != null) {
                android.util.Log.d("NativeTFLite", "Interpreter created successfully")
                isInitialized = true
                
                result.success(mapOf(
                    "success" to true,
                    "numLabels" to labels.size,
                    "message" to "Native TensorFlow Lite model initialized successfully"
                ))
            } else {
                throw Exception("Failed to create compatible interpreter")
            }
            
        } catch (e: Exception) {
            android.util.Log.e("NativeTFLite", "Model initialization failed: ${e.message}", e)
            
            // Check if this is an opcode compatibility issue
            val isOpcodeError = e.message?.contains("opcode", ignoreCase = true) == true ||
                              e.message?.contains("FULLY_CONNECTED", ignoreCase = true) == true
            
            val errorMessage = if (isOpcodeError) {
                "Model compatibility issue: Your model uses newer TensorFlow opcodes that are not supported by the current TensorFlow Lite runtime. Please use a model trained with TensorFlow 2.13-2.16 or update to a newer TensorFlow Lite version."
            } else {
                "Initialization failed: ${e.message}"
            }
            
            result.success(mapOf(
                "success" to false,
                "error" to errorMessage,
                "isCompatibilityIssue" to isOpcodeError
            ))
        }
    }
    
    private fun runInference(call: MethodCall, result: Result) {
        if (!isInitialized || interpreter == null) {
            return result.success(mapOf(
                "success" to false,
                "error" to "Model not initialized"
            ))
        }
        
        try {
            val imageBytes = call.argument<ByteArray>("imageBytes") ?: return result.error("INVALID_ARGS", "Image bytes required", null)
            val imagePath = call.argument<String>("imagePath") ?: ""
            
            val startTime = System.currentTimeMillis()
            
            // Decode image
            val originalBitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            if (originalBitmap == null) {
                return result.success(mapOf(
                    "success" to false,
                    "error" to "Failed to decode image"
                ))
            }
            
            android.util.Log.d("NativeTFLite", "🖼️ Original image: ${originalBitmap.width}x${originalBitmap.height}, config: ${originalBitmap.config}")
            
            // Resize image to exact model input size (384x384)
            val resizedBitmap = if (originalBitmap.width != INPUT_SIZE || originalBitmap.height != INPUT_SIZE) {
                android.util.Log.d("NativeTFLite", "🔄 Resizing image to ${INPUT_SIZE}x${INPUT_SIZE}")
                Bitmap.createScaledBitmap(originalBitmap, INPUT_SIZE, INPUT_SIZE, true)
            } else {
                originalBitmap
            }
            
            // Ensure bitmap is in ARGB_8888 format for consistent pixel extraction
            val processedBitmap = if (resizedBitmap.config != Bitmap.Config.ARGB_8888) {
                android.util.Log.d("NativeTFLite", "🎨 Converting bitmap to ARGB_8888")
                resizedBitmap.copy(Bitmap.Config.ARGB_8888, false)
            } else {
                resizedBitmap
            }
            
            android.util.Log.d("NativeTFLite", "✅ Final processed image: ${processedBitmap.width}x${processedBitmap.height}, config: ${processedBitmap.config}")
            
            // Preprocess image for model input
            val inputBuffer = preprocessImage(processedBitmap)
            
            // Run actual TensorFlow Lite inference
            val outputArray = Array(1) { FloatArray(OUTPUT_SIZE) }
            interpreter!!.run(inputBuffer, outputArray)
            val predictions = postprocessOutput(outputArray[0])
            
            val processingTime = System.currentTimeMillis() - startTime
            
            result.success(mapOf(
                "success" to true,
                "predictions" to predictions,
                "processingTime" to processingTime,
                "imageSize" to mapOf(
                    "width" to originalBitmap.width,
                    "height" to originalBitmap.height
                )
            ))
            
        } catch (e: Exception) {
            result.success(mapOf(
                "success" to false,
                "error" to "Inference failed: ${e.message}"
            ))
        }
    }
    
    private fun isSupported(result: Result) {
        result.success(mapOf(
            "supported" to true,
            "message" to "Native TensorFlow Lite fully implemented"
        ))
    }
    
    private fun getInfo(result: Result) {
        result.success(mapOf(
            "platform" to "Android",
            "version" to "1.0.0",
            "capabilities" to listOf("image_preprocessing", "tensorflow_lite", "real_inference"),
            "status" to "Fully operational"
        ))
    }
    
    private fun debugListAssets() {
        try {
            android.util.Log.d("NativeTFLite", "=== Asset Debug Information ===")
            
            // List root assets
            val rootAssets = context.assets.list("") ?: arrayOf()
            android.util.Log.d("NativeTFLite", "Root assets: ${rootAssets.joinToString(", ")}")
            
            // List models directory if it exists
            try {
                val modelsAssets = context.assets.list("models") ?: arrayOf()
                android.util.Log.d("NativeTFLite", "Models directory assets: ${modelsAssets.joinToString(", ")}")
            } catch (e: Exception) {
                android.util.Log.w("NativeTFLite", "Models directory not found: ${e.message}")
            }
            
            // Try flutter_assets prefix (common in Flutter apps)
            try {
                val flutterAssets = context.assets.list("flutter_assets") ?: arrayOf()
                android.util.Log.d("NativeTFLite", "Flutter assets directory: ${flutterAssets.joinToString(", ")}")
                
                if (flutterAssets.isNotEmpty()) {
                    try {
                        val flutterModels = context.assets.list("flutter_assets/assets/models") ?: arrayOf()
                        android.util.Log.d("NativeTFLite", "Flutter models assets: ${flutterModels.joinToString(", ")}")
                    } catch (e: Exception) {
                        android.util.Log.w("NativeTFLite", "Flutter models directory not found: ${e.message}")
                    }
                }
            } catch (e: Exception) {
                android.util.Log.w("NativeTFLite", "Flutter assets directory not found: ${e.message}")
            }
            
            android.util.Log.d("NativeTFLite", "=== End Asset Debug ===")
        } catch (e: Exception) {
            android.util.Log.e("NativeTFLite", "Error during asset debugging: ${e.message}")
        }
    }
    
    /**
     * Creates a TensorFlow Lite interpreter with compatibility handling for opcode versions
     */
    private fun createCompatibleInterpreter(modelBuffer: ByteBuffer): Interpreter? {
        android.util.Log.d("NativeTFLite", "Attempting to create compatible interpreter...")
        
        // Try different interpreter options for compatibility
        val options = arrayOf(
            // Standard options
            Interpreter.Options(),
            
            // Options with different threading configurations
            Interpreter.Options().apply { setNumThreads(1) },
            Interpreter.Options().apply { setNumThreads(4) },
            
            // Options with GPU delegate disabled (fallback)
            Interpreter.Options().apply { 
                setUseNNAPI(false)
                setAllowFp16PrecisionForFp32(false)
            }
        )
        
        for (i in options.indices) {
            try {
                android.util.Log.d("NativeTFLite", "Trying interpreter options configuration ${i + 1}/${options.size}")
                val interpreter = Interpreter(modelBuffer, options[i])
                android.util.Log.d("NativeTFLite", "✅ Successfully created interpreter with configuration ${i + 1}")
                return interpreter
            } catch (e: Exception) {
                android.util.Log.w("NativeTFLite", "Configuration ${i + 1} failed: ${e.message}")
                
                // Log specific opcode errors for debugging
                if (e.message?.contains("opcode", ignoreCase = true) == true) {
                    android.util.Log.e("NativeTFLite", "⚠️ Opcode compatibility issue detected: ${e.message}")
                }
            }
        }
        
        android.util.Log.e("NativeTFLite", "❌ Failed to create interpreter with any configuration")
        return null
    }
    
    private fun loadModelFromAssets(modelPath: String): ByteBuffer {
        val possiblePaths = listOf(
            modelPath.removePrefix("assets/"),  // models/model.tflite
            "flutter_assets/$modelPath",        // flutter_assets/assets/models/model.tflite
            "flutter_assets/assets/models/model.tflite", // Direct path
            "assets/models/model.tflite"        // Full assets path
        )
        
        for (path in possiblePaths) {
            try {
                android.util.Log.d("NativeTFLite", "Trying to load model from path: $path")
                
                // First try openFd for uncompressed assets
                try {
                    val assetFileDescriptor = context.assets.openFd(path)
                    android.util.Log.d("NativeTFLite", "✅ openFd succeeded for path: $path, size: ${assetFileDescriptor.length}")
                    
                    val fileInputStream = FileInputStream(assetFileDescriptor.fileDescriptor)
                    val fileChannel = fileInputStream.channel
                    val startOffset = assetFileDescriptor.startOffset
                    val declaredLength = assetFileDescriptor.declaredLength
                    
                    val buffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
                    android.util.Log.d("NativeTFLite", "✅ Model loaded successfully via openFd, buffer capacity: ${buffer.capacity()}")
                    
                    return buffer
                } catch (e: IOException) {
                    android.util.Log.d("NativeTFLite", "openFd failed for path $path: ${e.message}")
                    
                    // Fallback: Load using InputStream for compressed assets
                    val inputStream = context.assets.open(path)
                    val modelBytes = inputStream.readBytes()
                    inputStream.close()
                    
                    android.util.Log.d("NativeTFLite", "✅ Model loaded successfully via InputStream for path: $path, size: ${modelBytes.size} bytes")
                    
                    val buffer = ByteBuffer.allocateDirect(modelBytes.size)
                    buffer.order(ByteOrder.nativeOrder())
                    buffer.put(modelBytes)
                    buffer.rewind()
                    
                    return buffer
                }
            } catch (e: Exception) {
                android.util.Log.d("NativeTFLite", "Failed to load from path $path: ${e.message}")
            }
        }
        
        throw Exception("Model file not found in any of the attempted paths: ${possiblePaths.joinToString(", ")}")
    }
    
    private fun loadLabelsFromAssets(labelsPath: String): List<String> {
        val possiblePaths = listOf(
            labelsPath.removePrefix("assets/"),  // models/labels.txt
            "flutter_assets/$labelsPath",        // flutter_assets/assets/models/labels.txt
            "flutter_assets/assets/models/labels.txt", // Direct path
            "assets/models/labels.txt"          // Full assets path
        )
        
        for (path in possiblePaths) {
            try {
                android.util.Log.d("NativeTFLite", "Trying to load labels from path: $path")
                val inputStream = context.assets.open(path)
                val labels = inputStream.bufferedReader().readLines()
                    .filter { it.isNotEmpty() && it.trim().isNotEmpty() }
                inputStream.close()
                
                android.util.Log.d("NativeTFLite", "✅ Labels loaded successfully from path: $path, count: ${labels.size}")
                if (labels.isNotEmpty()) {
                    android.util.Log.d("NativeTFLite", "First few labels: ${labels.take(5).joinToString(", ")}")
                }
                return labels
            } catch (e: Exception) {
                android.util.Log.d("NativeTFLite", "Failed to load labels from path $path: ${e.message}")
            }
        }
        
        android.util.Log.w("NativeTFLite", "Labels file not found in any of the attempted paths: ${possiblePaths.joinToString(", ")}")
        return emptyList()
    }
    
    private fun postprocessOutput(output: FloatArray): List<Map<String, Any>> {
        android.util.Log.d("NativeTFLite", "📈 Model output array length: ${output.size}")
        
        val predictions = mutableListOf<Map<String, Any>>()
        
        // Find top 5 predictions for debugging
        val sortedIndices = output.indices.sortedByDescending { output[it] }
        android.util.Log.d("NativeTFLite", "🔝 Top 5 raw predictions:")
        for (i in 0 until minOf(5, sortedIndices.size)) {
            val index = sortedIndices[i]
            val label = if (index < labels.size) labels[index] else "unknown_$index"
            android.util.Log.d("NativeTFLite", "  $i: $label (index $index) = ${output[index]}")
        }
        
        for (i in output.indices) {
            if (i < labels.size && output[i] > 0.1) { // 10% confidence threshold
                predictions.add(mapOf(
                    "label" to labels[i],
                    "confidence" to output[i].toDouble(),
                    "index" to i
                ))
            }
        }
        
        // Sort by confidence (highest first)
        val sortedPredictions = predictions.sortedByDescending { it["confidence"] as Double }
        android.util.Log.d("NativeTFLite", "✅ Final predictions above threshold: ${sortedPredictions.size}")
        
        return sortedPredictions
    }
    
    private fun preprocessImage(bitmap: Bitmap): ByteBuffer {
        android.util.Log.d("NativeTFLite", "🔍 Preprocessing image: ${bitmap.width}x${bitmap.height}, config: ${bitmap.config}")
        
        val inputBuffer = ByteBuffer.allocateDirect(4 * INPUT_SIZE * INPUT_SIZE * 3)
        inputBuffer.order(ByteOrder.nativeOrder())
        
        val pixels = IntArray(INPUT_SIZE * INPUT_SIZE)
        bitmap.getPixels(pixels, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)
        
        android.util.Log.d("NativeTFLite", "📊 First 10 pixel values: ${pixels.take(10).joinToString(", ")}")
        
        // Apply EfficientNetV2 preprocessing as per memory specification
        var rSum = 0f
        var gSum = 0f
        var bSum = 0f
        
        for (pixel in pixels) {
            val r = ((pixel shr 16 and 0xFF) / 255.0f - 0.485f) / 0.229f
            val g = ((pixel shr 8 and 0xFF) / 255.0f - 0.456f) / 0.224f
            val b = ((pixel and 0xFF) / 255.0f - 0.406f) / 0.225f
            
            inputBuffer.putFloat(r)
            inputBuffer.putFloat(g)
            inputBuffer.putFloat(b)
            
            rSum += r
            gSum += g
            bSum += b
        }
        
        val numPixels = pixels.size
        android.util.Log.d("NativeTFLite", "📊 Preprocessed averages - R: ${rSum/numPixels}, G: ${gSum/numPixels}, B: ${bSum/numPixels}")
        
        return inputBuffer
    }

}