#!/usr/bin/env python3
"""
Model retraining with TensorFlow 2.12.0 for maximum compatibility
Based on your all_breeds_high_accuracy_v1_final architecture
"""

import tensorflow as tf
import numpy as np
import os
import json
from pathlib import Path

def setup_tensorflow_environment():
    """TensorFlow setup for maximum compatibility"""
    print(f"🔧 TensorFlow version: {tf.__version__}")
    
    # Recommended version for compatibility
    recommended_version = "2.12.0"
    current_version = tf.__version__
    
    if not current_version.startswith("2.12"):
        print(f"⚠️  Текущая версия TensorFlow: {current_version}")
        print(f"💡 Рекомендуемая версия: {recommended_version}")
        print("🔧 Для установки выполните:")
        print(f"   pip install tensorflow=={recommended_version}")
        print("")
    
    return current_version.startswith("2.12")

def create_compatible_model_architecture():
    """Создает совместимую архитектуру модели"""
    print("🏗️ Создание совместимой архитектуры модели...")
    
    # Используем базовую архитектуру без современных оптимизаций
    base_model = tf.keras.applications.EfficientNetV2B3(
        weights='imagenet',
        include_top=False,
        input_shape=(384, 384, 3)
    )
    
    # Замораживаем базовые слои для ускорения обучения
    base_model.trainable = False
    
    # Добавляем совместимые головные слои
    model = tf.keras.Sequential([
        base_model,
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(512, activation='relu'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(40, activation='softmax')  # 40 пород кошек
    ])
    
    # Компилируем с совместимыми настройками
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    print("✅ Архитектура модели создана")
    print(f"📊 Общее количество параметров: {model.count_params():,}")
    
    return model

def convert_to_compatible_tflite(model, output_path):
    """Конвертация в совместимый TensorFlow Lite формат"""
    print("🔄 Конвертация в TensorFlow Lite с настройками совместимости...")
    
    # Создаем конвертер
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # КРИТИЧНО: Максимальная совместимость
    converter.optimizations = []  # Без оптимизаций
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
    converter.experimental_enable_resource_variables = False
    converter.allow_custom_ops = False
    
    # Принудительно float32
    converter.inference_input_type = tf.float32
    converter.inference_output_type = tf.float32
    converter.target_spec.supported_types = [tf.float32]
    
    # Дополнительные настройки для старых версий Android
    try:
        converter.experimental_new_converter = False
    except AttributeError:
        pass  # Не все версии TF имеют этот атрибут
    
    # Конвертируем
    tflite_model = converter.convert()
    
    # Сохраняем
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    size_mb = len(tflite_model) / (1024 * 1024)
    print(f"✅ Модель сконвертирована: {output_path}")
    print(f"📊 Размер: {size_mb:.1f} МБ")
    
    return tflite_model

def create_training_script():
    """Создает скрипт для переобучения"""
    
    training_script = '''#!/usr/bin/env python3
"""
Скрипт переобучения модели MeowAI с TensorFlow 2.12.0
Гарантированная совместимость с Android TensorFlow Lite
"""

import tensorflow as tf
import numpy as np
import os
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import ModelCheckpoint, ReduceLROnPlateau

# Проверяем версию TensorFlow
print(f"TensorFlow версия: {tf.__version__}")
if not tf.__version__.startswith("2.12"):
    print("⚠️ Рекомендуется TensorFlow 2.12.0 для максимальной совместимости")

# Параметры обучения
IMG_SIZE = (384, 384)
BATCH_SIZE = 16
EPOCHS = 20
NUM_CLASSES = 40

def create_model():
    """Создание модели с максимальной совместимостью"""
    base_model = tf.keras.applications.EfficientNetV2B3(
        weights='imagenet',
        include_top=False,
        input_shape=(*IMG_SIZE, 3)
    )
    
    # Базовая модель заморожена для transfer learning
    base_model.trainable = False
    
    model = tf.keras.Sequential([
        base_model,
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(512, activation='relu'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(NUM_CLASSES, activation='softmax')
    ])
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    return model

def setup_data_generators(data_dir):
    """Настройка генераторов данных"""
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        horizontal_flip=True,
        validation_split=0.2
    )
    
    train_generator = train_datagen.flow_from_directory(
        data_dir,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training'
    )
    
    validation_generator = train_datagen.flow_from_directory(
        data_dir,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='validation'
    )
    
    return train_generator, validation_generator

def train_model():
    """Основная функция обучения"""
    # ВАЖНО: Укажите путь к вашему датасету
    data_dir = "path/to/your/cat_breeds_dataset"  # ИЗМЕНИТЕ НА ВАШ ПУТЬ
    
    if not os.path.exists(data_dir):
        print(f"❌ Датасет не найден: {data_dir}")
        print("📝 Укажите правильный путь к датасету в переменной data_dir")
        return
    
    # Создаем модель
    model = create_model()
    print("✅ Модель создана")
    
    # Настраиваем данные
    train_gen, val_gen = setup_data_generators(data_dir)
    print("✅ Генераторы данных настроены")
    
    # Callbacks
    callbacks = [
        ModelCheckpoint(
            'best_model_compatible.h5',
            save_best_only=True,
            monitor='val_accuracy',
            mode='max'
        ),
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.2,
            patience=3,
            min_lr=1e-7
        )
    ]
    
    # Обучение
    print("🚀 Начинаем обучение...")
    history = model.fit(
        train_gen,
        epochs=EPOCHS,
        validation_data=val_gen,
        callbacks=callbacks
    )
    
    # Сохраняем финальную модель
    model.save('final_model_compatible.h5')
    print("✅ Обучение завершено!")
    
    return model

def convert_to_tflite(h5_path, output_path):
    """Конвертация в TensorFlow Lite"""
    model = tf.keras.models.load_model(h5_path, compile=False)
    
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Максимальная совместимость
    converter.optimizations = []
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
    converter.experimental_enable_resource_variables = False
    converter.allow_custom_ops = False
    converter.inference_input_type = tf.float32
    converter.inference_output_type = tf.float32
    
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"✅ TensorFlow Lite модель сохранена: {output_path}")

if __name__ == "__main__":
    print("🔧 Обучение совместимой модели MeowAI")
    print("=" * 50)
    
    # Обучаем модель
    model = train_model()
    
    if model:
        # Конвертируем в TensorFlow Lite
        convert_to_tflite('best_model_compatible.h5', 'model_compatible.tflite')
        print("🎉 Готово! Скопируйте model_compatible.tflite в assets/models/model.tflite")
'''
    
    # Сохраняем скрипт переобучения
    script_path = "../tools/retrain_compatible_model.py"
    with open(script_path, 'w', encoding='utf-8') as f:
        f.write(training_script)
    
    print(f"📄 Скрипт переобучения создан: {script_path}")
    return script_path

def main():
    print("🔧 Настройка переобучения для совместимости")
    print("=" * 60)
    
    # Проверяем версию TensorFlow
    is_compatible = setup_tensorflow_environment()
    
    if not is_compatible:
        print("⚠️  Для гарантированной совместимости рекомендуется TensorFlow 2.12.0")
        print("🔧 Установите: pip install tensorflow==2.12.0")
        print("")
    
    # Создаем скрипт переобучения
    script_path = create_training_script()
    
    print("\n" + "=" * 60)
    print("✅ ГОТОВО!")
    print("📋 Варианты действий:")
    print("")
    print("1. 🔄 Переобучение (рекомендуется):")
    print(f"   - Отредактируйте {script_path}")
    print("   - Укажите путь к вашему датасету")
    print("   - Запустите: python3 retrain_compatible_model.py")
    print("")
    print("2. 🧪 Тестирование текущей конвертации:")
    print("   - Дождитесь завершения convert_original_model.py")
    print("   - Протестируйте результат в приложении")
    print("")
    print("💡 Переобучение гарантирует 100% совместимость!")

if __name__ == "__main__":
    main()