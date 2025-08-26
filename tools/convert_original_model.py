#!/usr/bin/env python3
"""
Converting original model all_breeds_high_accuracy_v1_final.h5
to compatible TensorFlow Lite format for Android
"""

import tensorflow as tf
import numpy as np
import os
import json
from pathlib import Path

def convert_original_model():
    """Converts original H5 model to compatible TFLite format"""
    print("🔄 Converting original model all_breeds_high_accuracy_v1_final.h5")
    print("=" * 80)
    
    # File paths
    h5_path = "../scripts/training/all_breeds_high_accuracy_v1_final.h5"
    output_path = "../assets/models/model.tflite"
    
    # Check if H5 model exists
    if not os.path.exists(h5_path):
        print(f"❌ H5 model not found: {h5_path}")
        return False
    
    print(f"📂 Loading H5 model: {h5_path}")
    file_size = os.path.getsize(h5_path) / (1024 * 1024)
    print(f"📊 Размер H5 модели: {file_size:.1f} МБ")
    
    try:
        # Load model without compilation to avoid version conflicts
        print("⏳ Загрузка модели (может занять время)...")
        model = tf.keras.models.load_model(h5_path, compile=False)
        print("✅ H5 модель успешно загружена")
        
        # Выводим информацию о модели
        print(f"📊 Архитектура модели:")
        print(f"   Входной размер: {model.input_shape}")
        print(f"   Выходной размер: {model.output_shape}")
        print(f"   Количество параметров: {model.count_params():,}")
        
        # Создаем конвертер с МАКСИМАЛЬНЫМИ настройками совместимости
        print("🔧 Настройка конвертера для максимальной совместимости...")
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # КРИТИЧНО: Принудительно используем старые версии операций
        converter.optimizations = []  # Никаких оптимизаций
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
        converter.experimental_enable_resource_variables = False
        converter.allow_custom_ops = False
        
        # Принудительно используем float32
        converter.inference_input_type = tf.float32
        converter.inference_output_type = tf.float32
        converter.target_spec.supported_types = [tf.float32]
        
        # Дополнительные настройки совместимости
        try:
            # Пытаемся отключить современные оптимизации
            converter.experimental_new_converter = False
        except:
            pass  # Если атрибут не существует в этой версии TF
        
        print("🔄 Конвертация в TensorFlow Lite (это займет несколько минут)...")
        print("⚠️  Процесс может показаться 'зависшим' - это нормально для больших моделей")
        
        # Конвертируем модель
        tflite_model = converter.convert()
        
        # Создаем резервную копию предыдущей модели
        if os.path.exists(output_path):
            backup_path = output_path.replace('.tflite', '_previous_backup.tflite')
            os.rename(output_path, backup_path)
            print(f"💾 Предыдущая модель сохранена как: {backup_path}")
        
        # Сохраняем сконвертированную модель
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        converted_size = len(tflite_model) / (1024 * 1024)
        print(f"✅ Модель успешно сконвертирована: {output_path}")
        print(f"📊 Размер сконвертированной модели: {converted_size:.1f} МБ")
        print(f"📉 Сжатие: {file_size:.1f}МБ → {converted_size:.1f}МБ")
        
        # Тестируем совместимость сконвертированной модели
        print("🧪 Тестирование совместимости...")
        
        try:
            interpreter = tf.lite.Interpreter(model_content=tflite_model)
            interpreter.allocate_tensors()
            
            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            
            print("✅ ТЕСТ СОВМЕСТИМОСТИ ПРОЙДЕН!")
            print(f"📥 Входной тензор: {input_details[0]['shape']}")
            print(f"📤 Выходной тензор: {output_details[0]['shape']}")
            
            # Тестируем инференс
            test_input = np.random.rand(*input_details[0]['shape']).astype(np.float32)
            interpreter.set_tensor(input_details[0]['index'], test_input)
            interpreter.invoke()
            
            output = interpreter.get_tensor(output_details[0]['index'])
            print(f"✅ Тестовый инференс успешен! Форма выхода: {output.shape}")
            
            return True
            
        except Exception as e:
            print(f"❌ ТЕСТ СОВМЕСТИМОСТИ НЕ ПРОЙДЕН: {e}")
            
            # Проверяем на ошибку FULLY_CONNECTED
            if "FULLY_CONNECTED" in str(e) and "version" in str(e):
                print("⚠️  Обнаружена проблема совместимости операций FULLY_CONNECTED")
                print("🔧 Это означает, что модель была обучена с более новой версией TensorFlow")
                print("💡 РЕШЕНИЕ: Переобучить модель с TensorFlow 2.12.0")
                
                # Сохраняем модель как есть - может работать на некоторых устройствах
                print("📝 Модель сохранена, но может не работать на всех Android устройствах")
                return "partial"
            
            return False
            
    except Exception as e:
        print(f"❌ Ошибка конвертации: {e}")
        return False

def update_model_info_for_real_model():
    """Обновляет информацию о модели для реальной сконвертированной модели"""
    model_info = {
        "model_name": "all_breeds_high_accuracy_v1_final_converted",
        "version": "1.0.0",
        "compatibility": "Сконвертировано для совместимости с TensorFlow Lite",
        "type": "EfficientNetV2-B3 (оригинальная модель, сконвертированная)",
        "input_size": [384, 384, 3],
        "output_size": 40,
        "num_classes": 40,
        "note": "Оригинальная обученная модель, сконвертированная для Android",
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
    with open(info_path, 'w', encoding='utf-8') as f:
        json.dump(model_info, f, indent=2, ensure_ascii=False)
    
    print(f"📄 Информация о модели обновлена: {info_path}")

def main():
    print("🚀 Конвертер оригинальной модели MeowAI")
    print("=" * 80)
    print("Конвертируем вашу обученную модель all_breeds_high_accuracy_v1_final.h5")
    print("в совместимый TensorFlow Lite формат для Android.")
    print("")
    
    # Проверяем версию TensorFlow
    print(f"🔧 Используемая версия TensorFlow: {tf.__version__}")
    print("")
    
    result = convert_original_model()
    
    if result == True:
        update_model_info_for_real_model()
        
        print("\n" + "=" * 80)
        print("🎉 УСПЕХ!")
        print("✅ Ваша оригинальная модель успешно сконвертирована!")
        print("🚀 Это должно решить проблему совместимости FULLY_CONNECTED!")
        print("")
        print("🔄 Следующие шаги:")
        print("1. Полная пересборка Flutter приложения")
        print("2. Тестирование - вы увидите НАСТОЯЩЕЕ распознавание пород кошек!")
        print("3. Приложение будет использовать вашу реальную обученную модель")
        
    elif result == "partial":
        update_model_info_for_real_model()
        
        print("\n" + "=" * 80)
        print("⚠️  ЧАСТИЧНЫЙ УСПЕХ")
        print("✅ Модель сконвертирована, но может иметь проблемы совместимости")
        print("🔧 Рекомендуется переобучение с TensorFlow 2.12.0")
        print("")
        print("🔄 Варианты:")
        print("1. Попробовать текущую модель (может работать)")
        print("2. Переобучить модель с TensorFlow 2.12.0 (гарантированно работает)")
        
    else:
        print("\n" + "=" * 80)
        print("❌ КОНВЕРТАЦИЯ НЕ УДАЛАСЬ!")
        print("🔧 Возможные решения:")
        print("1. Переобучить модель с TensorFlow 2.12.0")
        print("2. Использовать мок-модель временно")
        print("3. Проверить доступность H5 файла")

if __name__ == "__main__":
    main()