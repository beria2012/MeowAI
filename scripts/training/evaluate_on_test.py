#!/usr/bin/env python3
"""
Evaluate a saved Keras model on images in a `test` folder.

Usage examples:
  python evaluate_on_test.py --model models/all_breeds_high_accuracy_v1_final.h5 --test-dir test

The script supports two test folder layouts:
  - test/<class_name>/*.jpg  (uses ground-truth labels and will compute report+confusion)
  - test/*.jpg               (no labels; will output per-image top-k predictions)

Outputs saved under `models/`:
  - test_predictions.csv         (per-image predictions)
  - test_classification_report.json / .csv  (if labeled)
  - test_confusion_matrix.png    (if labeled)
"""
import os
import sys
import json
import argparse
from pathlib import Path
import numpy as np

try:
    import tensorflow as tf
    from tensorflow.keras.preprocessing.image import ImageDataGenerator
    from tensorflow.keras.applications.efficientnet_v2 import preprocess_input
except Exception as e:
    print('TensorFlow import failed:', e)
    raise

try:
    from sklearn.metrics import classification_report, confusion_matrix
except Exception:
    classification_report = None
    confusion_matrix = None

try:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import seaborn as sns
except Exception:
    plt = None
    sns = None


def ensure_models_dir():
    models_dir = Path('models')
    models_dir.mkdir(parents=True, exist_ok=True)
    return models_dir


def build_and_save_class_indices(models_dir: Path):
    """Attempt to build class_indices.json by scanning likely training dataset folders.
    Returns the loaded mapping (label->index).
    """
    candidates = [Path('balanced_all_breeds_dataset'), Path('cat-breeds'), Path('balanced_dataset'), Path('dataset')]
    found = None
    for c in candidates:
        if c.exists() and c.is_dir():
            # ensure it contains subfolders (classes)
            sub = [p for p in c.iterdir() if p.is_dir()]
            if sub:
                found = c
                break
    # Prefer loading comprehensive results which contains training class order
    comp_file = Path('all_breeds_high_accuracy_v1_comprehensive_results.json')
    if comp_file.exists():
        try:
            with comp_file.open('r') as fh:
                data = json.load(fh)
                class_names = data.get('class_names')
                if class_names:
                    mapping = {name: idx for idx, name in enumerate(class_names)}
                    ci_path = models_dir / 'class_indices.json'
                    with ci_path.open('w') as fh2:
                        json.dump(mapping, fh2, indent=2, ensure_ascii=False)
                    print(f'Built class_indices.json from comprehensive results ({comp_file}) with {len(mapping)} classes')
                    return mapping
        except Exception as e:
            print('Failed to load comprehensive results file:', e)

    if not found:
        return None

    # list subfolder names sorted (flow_from_directory uses alphabetical order)
    class_names = sorted([p.name for p in found.iterdir() if p.is_dir()])
    mapping = {name: idx for idx, name in enumerate(class_names)}
    ci_path = models_dir / 'class_indices.json'
    try:
        with ci_path.open('w') as fh:
            json.dump(mapping, fh, indent=2, ensure_ascii=False)
        print(f'Built class_indices.json from {found} with {len(mapping)} classes')
    except Exception as e:
        print('Failed to write class_indices.json:', e)
    return mapping


def load_model(path):
    print('Loading model:', path)
    model = tf.keras.models.load_model(path, compile=False)
    return model


def evaluate_directory_with_subfolders(model, test_dir, image_size, batch_size, top_k, models_dir):
    datagen = ImageDataGenerator(preprocessing_function=preprocess_input)
    generator = datagen.flow_from_directory(
        test_dir,
        target_size=(image_size, image_size),
        batch_size=batch_size,
        class_mode='categorical',
        shuffle=False
    )

    print('Running predictions on', generator.samples, 'images...')
    preds = model.predict(generator, verbose=1)

    y_true = generator.classes
    class_indices = generator.class_indices
    # invert mapping to get index -> label
    index_to_label = {v: k for k, v in class_indices.items()}
    filenames = generator.filenames

    y_pred = np.argmax(preds, axis=1)

    # Print per-image predictions (do not write CSV)
    for i, fname in enumerate(filenames):
        true = index_to_label[int(y_true[i])]
        p = preds[i]
        topk_idx = np.argsort(p)[::-1][:top_k]
        topk_labels = [index_to_label[int(j)] for j in topk_idx]
        topk_probs = [float(p[int(j)]) for j in topk_idx]
        pred_label = index_to_label[int(y_pred[i])]
        pred_prob = float(p[int(y_pred[i])])
        try:
            print(f"{fname} -> true: {true}  pred: {pred_label} ({pred_prob:.3f})  top-{len(topk_labels)}: {topk_labels}")
        except Exception:
            print(fname, '->', pred_label)

    # classification report & confusion matrix
    if classification_report is None or confusion_matrix is None:
        print('sklearn not available: skipping classification report and confusion matrix')
        return

    target_names = [index_to_label[i] for i in range(len(index_to_label))]
    report = classification_report(y_true, y_pred, target_names=target_names, output_dict=True)
    report_json = models_dir / 'test_classification_report.json'
    with report_json.open('w') as fh:
        json.dump(report, fh, indent=2, ensure_ascii=False)
    print('Saved classification report (json) to', report_json)

    # CSV report not required; results saved as JSON and printed to console

    # confusion matrix plot
    cm = confusion_matrix(y_true, y_pred)
    if plt is not None and sns is not None:
        plt.figure(figsize=(12, 10))
        sns.heatmap(cm, annot=False, fmt='d', cmap='Blues')
        plt.ylabel('True')
        plt.xlabel('Predicted')
        plt.title('Confusion Matrix')
        cm_png = models_dir / 'test_confusion_matrix.png'
        plt.tight_layout()
        plt.savefig(cm_png, dpi=150)
        print('Saved confusion matrix to', cm_png)
    else:
        print('matplotlib/seaborn not available: skipping confusion matrix image')


def evaluate_flat_directory(model, test_dir, image_size, batch_size, top_k, models_dir):
    # predict each image file and print top-k predictions (no CSV)
    files = [p for p in Path(test_dir).iterdir() if p.is_file() and p.suffix.lower() in ('.jpg', '.jpeg', '.png')]
    files.sort()
    # try to load class mapping once
    ci_path = models_dir / 'class_indices.json'
    if ci_path.exists():
        try:
            with ci_path.open('r') as fh2:
                label_map = json.load(fh2)
                index_to_label = {int(v): k for k, v in label_map.items()}
        except Exception:
            index_to_label = None
    else:
        index_to_label = None

    for p in files:
        img = tf.keras.preprocessing.image.load_img(str(p), target_size=(image_size, image_size))
        arr = tf.keras.preprocessing.image.img_to_array(img)
        arr = np.expand_dims(arr, 0)
        arr = preprocess_input(arr)
        preds = model.predict(arr)
        pvec = preds[0]
        topk_idx = np.argsort(pvec)[::-1][:top_k]
        if index_to_label:
            topk_labels = [index_to_label.get(int(i), str(i)) for i in topk_idx]
        else:
            topk_labels = [str(int(i)) for i in topk_idx]
        topk_probs = [float(pvec[int(i)]) for i in topk_idx]
        try:
            print(f"{p.name} -> predicted: {topk_labels[0]} ({topk_probs[0]:.3f})")
        except Exception:
            print(p.name, '->', topk_labels[0] if topk_labels else 'unknown')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', default='models/all_breeds_high_accuracy_v1_final.h5')
    parser.add_argument('--test-dir', default='test')
    parser.add_argument('--image-size', type=int, default=384)
    parser.add_argument('--batch-size', type=int, default=16)
    parser.add_argument('--top-k', type=int, default=5)
    args = parser.parse_args()

    models_dir = ensure_models_dir()

    # Ensure class_indices.json exists (build from comprehensive results or dataset if needed)
    ci_path = models_dir / 'class_indices.json'
    if not ci_path.exists():
        built = build_and_save_class_indices(models_dir)
        if not built:
            print('Warning: class_indices.json not found and could not be built; flat test outputs will show numeric indices')

    if not Path(args.test_dir).exists():
        print('Test directory not found:', args.test_dir)
        sys.exit(1)

    model = load_model(args.model)

    # detect if test dir contains subfolders (class-labeled)
    entries = [p for p in Path(args.test_dir).iterdir() if p.is_dir()]
    if entries:
        evaluate_directory_with_subfolders(model, args.test_dir, args.image_size, args.batch_size, args.top_k, models_dir)
    else:
        evaluate_flat_directory(model, args.test_dir, args.image_size, args.batch_size, args.top_k, models_dir)


if __name__ == '__main__':
    main()
