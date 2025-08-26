#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cat Breeds Mega Dataset Downloader + Cleaner (FULL "turnkey")
==============================================================
What the script does:
1) Collects LARGE dataset of images of all (200+) cat breeds in structure:
      dataset/<breed_slug>/<images>.jpg
2) Supports Google Images (icrawler) with automatic fallback to Bing Images.
3) Keeps detailed log (dataset/_logs/dataset_builder.log).
4) After downloading — MAXIMUM cleanup:
   - Removes broken/invalid files and too small images.
   - Filters "is cat / not cat" (MobileNetV2 by ImageNet classes 281–285).
   - Removes exact duplicates (MD5) and near-duplicates (perceptual hash dHash).
   - Normalizes EXIF orientation, converts to .jpg (optionally).
5) Resumability: if breed folder already has enough images — skips download.
6) Creates manifest.csv with paths and metadata.

Dependencies (minimum):
    pip install icrawler pillow opencv-python-headless tensorflow==2.* numpy
Additional (optional, speeds up cleanup):
    pip install imagehash

Usage:
    python build_cat_dataset.py \
      --out dataset \
      --images-per-breed 300 \
      --engine auto \
      --min-size 128 \
      --cat-threshold 0.20 \
      --sleep 1.5

Note:
- Google may temporarily block: use --engine bing or leave auto.
- MobileNetV2 model on ImageNet is used exclusively for "is there a cat in the picture?" filter.

Author: for your use, without restrictions.
"""

from __future__ import annotations

import os
import re
import io
import cv2
import sys
import csv
import json
import time
import math
import glob
import uuid
import hashlib
import logging
import argparse
import traceback
from dataclasses import dataclass
from typing import List, Tuple, Dict, Optional

# --- Safe imports (some packages might not be installed) ---
try:
    from icrawler.builtin import GoogleImageCrawler, BingImageCrawler
    ICRAWLER_OK = True
except Exception:
    ICRAWLER_OK = False

try:
    import numpy as np
except Exception:
    print("❌ numpy is required")
    raise

try:
    from PIL import Image, ImageOps, UnidentifiedImageError
    PIL_OK = True
except Exception:
    PIL_OK = False

# TensorFlow for "is cat" check
TF_OK = True
try:
    import tensorflow as tf
    from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input, decode_predictions
except Exception:
    TF_OK = False

# Additional perceptual hash (if available). Otherwise use our own dHash implementation.
try:
    import imagehash  # noqa: F401
    IMAGEHASH_OK = True
except Exception:
    IMAGEHASH_OK = False


# ----------------------------- Breed list (220+ entries) -----------------------------
# Sources combined from CFA/TICA/WCF/encyclopedias; includes aliases and variations for better search coverage.
CAT_BREEDS: List[str] = [
    "Abyssinian cat", "Aegean cat", "American Bobtail cat", "American Curl cat",
    "American Ringtail cat", "American Shorthair cat", "American Wirehair cat",
    "Arabian Mau cat", "Asian cat", "Asian Semi-longhair cat", "Australian Mist cat",
    "Balinese cat", "Bambino cat", "Bengal cat", "Birman cat", "Bombay cat",
    "Brazilian Shorthair cat", "British Longhair cat", "British Shorthair cat",
    "Burmese cat", "Burmilla cat", "California Spangled cat", "Chantilly Tiffany cat",
    "Chartreux cat", "Chausie cat", "Cheetoh cat", "Colorpoint Shorthair cat",
    "Cornish Rex cat", "Cymric cat", "Cyprus cat", "Devon Rex cat", "Donskoy cat",
    "Dragon Li cat", "Dwelf cat", "Egyptian Mau cat", "European Burmese cat",
    "European Shorthair cat", "Exotic Shorthair cat", "Foldex cat", "German Rex cat",
    "Havana Brown cat", "Highlander cat", "Himalayan cat", "Japanese Bobtail cat",
    "Javanese cat", "Kanaani cat", "Khao Manee cat", "Korat cat",
    "Korean Bobtail cat", "Korn Ja cat", "Kurilian Bobtail cat", "LaPerm cat",
    "Lykoi cat", "Maine Coon cat", "Manx cat", "Mekong Bobtail cat", "Minskin cat",
    "Napoleon cat", "Neva Masquerade cat", "Munchkin cat", "Nebelung cat",
    "Norwegian Forest cat", "Ocicat cat", "Ojos Azules cat", "Oriental Bicolor cat",
    "Oriental Longhair cat", "Oriental Shorthair cat", "Persian cat",
    "Peterbald cat", "Pixie-bob cat", "Ragamuffin cat", "Ragdoll cat",
    "Russian Blue cat", "Sam Sawet cat", "Savannah cat", "Scottish Fold cat",
    "Scottish Straight cat", "Selkirk Rex cat", "Serengeti cat", "Serrade Petit cat",
    "Siamese cat", "Siberian cat", "Singapura cat", "Snowshoe cat", "Sokoke cat",
    "Somali cat", "Sphynx cat", "Suphalak cat", "Thai cat", "Tonkinese cat",
    "Toyger cat", "Toybob cat", "Turkish Angora cat", "Turkish Van cat",
    "Ukrainian Levkoy cat", "York Chocolate cat", "Ural Rex cat",
    "American Longhair cat", "Bicolor cat breed", "Calico cat breed",
    "Tabby cat breed", "Tuxedo cat breed",  # паттерны (для расширения поиска)
    "Chinese Li Hua cat", "Malayan cat", "Mandarin cat", "Mandalay cat",
    "Oriental Foreign White cat", "Black Persian cat", "Chinchilla Persian cat",
    "Teacup Persian cat", "Exotic Longhair cat", "British Blue cat",
    "German Longhair cat", "Korat Si-Sawat cat", "Mokema cat", "Skookum cat",
    "Australian Tiffanie cat", "Burmilla Longhair cat", "Oregon Rex cat",
    "Tasman Manx cat", "Tennessee Rex cat", "Thuringian Forest cat",
    "Asian Smoke cat", "Asian Tabby cat", "Asian Self cat", "Bombay European cat",
    "Caracal domestic hybrid cat", "Chaussie domestic hybrid cat", "Cheetoh hybrid cat",
    "Jungle Curl cat", "Highland Lynx cat", "Desert Lynx cat", "Lambkin cat",
    "Mandalay Burmese cat", "Minuet cat", "Napoleon Minuet cat", "Ojos Azules longhair cat",
    "Pixiebob Longhair cat", "Rex Longhair cat", "Rex Shorthair cat",
    "Snow Bengal cat", "Seal Lynx Point Siamese cat", "Blue Point Siamese cat",
    "Lilac Point Siamese cat", "Chocolate Point Siamese cat",
    "Colorpoint Persian cat", "Himalayan Persian cat",
    "Tiffanie cat", "Tiffany Chantilly cat", "Bali cat", "Balinese Javanese cat",
    "American Keuda cat", "American Polydactyl cat", "American Poodle cat",
    "Arabian Mau Longhair cat", "Asian Longhair cat", "Basilicata cat",
    "Brazilian Longhair cat", "British Colourpoint cat", "Canadian Sphynx cat",
    "Don Sphynx cat", "Elf cat", "Dwelf cat", "Minskin Dwelf cat",
    "Peterbald hairless cat", "Burmilla Tiffanie cat", "Euro-Burmese cat",
    "Istanbul cat", "Mekong Bobtail Longhair cat", "Kuril Bobtail Longhair cat",
    "Japanese Bobtail Longhair cat", "Korean Bobtail Longhair cat",
    "Karelian Bobtail cat", "American Lynx cat", "European Maine Coon cat",
    "Polish cat breed", "Thai Lilac cat", "Thai Blue Point cat", "Thai Seal Point cat",
    "Ural Rex Longhair cat", "Ussuri cat", "Van kedisi cat", "Ankara kedisi cat",
    "Aphrodite Giant cat", "Cyprus Aphrodite cat", "Bristol cat", "California Rex cat",
    "Kanaani German cat", "Lykoi Shorthair cat", "Mandalay New Zealand cat",
    "Me-kong Bobtail cat", "Owyhee Bob cat", "Pantherette cat", "Raas cat",
    "Safari cat", "Savannah F1 cat", "Savannah F2 cat", "Savannah F3 cat",
    "Serengeti hybrid cat", "Sokoke Forest cat", "Suphalak Thailand cat",
    "Thai Korat cat", "Toyger striped cat", "Turkish Van Vankedisi cat",
    "Turkish Angora Ankara kedisi cat", "York Chocolate Longhair cat",
    "Chausie hybrid cat", "Asian Burmilla cat", "Khaomanee cat", "Thai Siamese cat",
    "Ariègeois cat", "Brazilian Rex cat", "Snowshoe Longhair cat", "German Rex Longhair cat",
    "Highlander Shorthair cat", "Highlander Longhair cat", "American Curl Longhair cat",
    "American Curl Shorthair cat", "Siamese Modern cat", "Siamese Traditional cat",
    "Applehead Siamese cat", "Old-style Siamese cat", "Oriental Siamese cat",
    "Ceylon cat", "Mau Egyptian cat", "Havana Brown oriental cat",
    "Burmese European cat", "Burmese American cat", "British Golden Shaded cat",
    "British Silver Shaded cat", "British Black Golden Shaded cat",
    "Maine Coon polydactyl cat", "Ragdoll mitted cat", "Ragdoll bicolor cat",
    "Ragdoll colorpoint cat", "Ragamuffin longhair cat", "Manx longhair Cymric cat",
    "Manx rumpy cat", "Manx stumpy cat", "Siberian Neva Masquerade cat",
    "Norwegian Forest longhair cat", "Ocicat spotted cat", "Ocicat classic tabby cat",
    "Ocicat ticked tabby cat", "Russian Blue Archangel cat",
    "Khao Manee Diamond Eye cat", "Korat Si-Sawat Blue cat",
    "Bengal snow lynx point cat", "Bengal marble cat", "Bengal spotted cat",
    "Persian doll face cat", "Persian flat face cat",
    "Selkirk Rex Longhair cat", "Selkirk Rex Shorthair cat",
    "Scottish Fold Longhair cat", "Scottish Fold Shorthair cat",
    "Scottish Straight Longhair cat", "Scottish Straight Shorthair cat",
    "Oriental Foreign White Longhair cat", "Oriental Foreign White Shorthair cat",
    "Balinese modern cat", "Javanese longhair cat", "Japanese Bobtail Mi-ke cat",
    "Japanese Bobtail calico cat", "Turkish Van swimming cat",
    "Himalayan colorpoint Persian cat", "Exotic Shorthair flat face cat",
    "Exotic Longhair Persian type cat"
]

# ---------------------------- Command line arguments -----------------------------
def parse_args():
    p = argparse.ArgumentParser(
        description="Collection and cleaning of huge cat breed image dataset."
    )
    p.add_argument("--out", type=str, default="dataset", help="Dataset folder")
    p.add_argument("--images-per-breed", type=int, default=300, help="Target images per breed")
    p.add_argument("--engine", type=str, default="auto", choices=["auto", "google", "bing"],
                   help="Search engine: google|bing|auto (with fallback)")
    p.add_argument("--sleep", type=float, default=1.0, help="Pause between breeds (sec.)")
    p.add_argument("--min-size", type=int, default=128, help="Min. side size, px")
    p.add_argument("--min-files-to-skip", type=int, default=240,
                   help="If already >= N files in breed folder, skip download (for resuming)")
    p.add_argument("--cat-threshold", type=float, default=0.20,
                   help="Confidence threshold (ImageNet) to consider image 'cat'")
    p.add_argument("--max-total-per-breed", type=int, default=1000,
                   help="Hard max downloaded files per breed (safety)")
    p.add_argument("--jpg-only", action="store_true",
                   help="Save/convert images to .jpg (recommended)")
    p.add_argument("--keep-intermediate", action="store_true",
                   help="Don't delete originals when converting to .jpg")
    p.add_argument("--no-is-cat", action="store_true",
                   help="DISABLE 'is cat' check (faster, but lower quality)")
    p.add_argument("--no-near-dup", action="store_true",
                   help="DISABLE near-duplicate removal (dHash)")
    p.add_argument("--limit-breeds", type=int, default=0,
                   help="Limit number of breeds (for testing). 0 = no limit.")
    return p.parse_args()


# ------------------------------ Logging ------------------------------
def make_logger(out_dir: str) -> logging.Logger:
    log_dir = os.path.join(out_dir, "_logs")
    os.makedirs(log_dir, exist_ok=True)
    log_path = os.path.join(log_dir, "dataset_builder.log")

    logger = logging.getLogger("dataset-builder")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()

    fmt = logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")

    fh = logging.FileHandler(log_path, encoding="utf-8")
    fh.setLevel(logging.INFO)
    fh.setFormatter(fmt)
    logger.addHandler(fh)

    sh = logging.StreamHandler(sys.stdout)
    sh.setLevel(logging.INFO)
    sh.setFormatter(fmt)
    logger.addHandler(sh)

    logger.info("Logs are written to %s", log_path)
    return logger


# ------------------------------ Utilities ------------------------------
def slugify(name: str) -> str:
    name = name.strip().lower()
    name = re.sub(r"[^a-z0-9]+", "_", name)
    name = re.sub(r"_+", "_", name).strip("_")
    return name


def list_images(folder: str) -> List[str]:
    exts = ("*.jpg", "*.jpeg", "*.png", "*.bmp", "*.webp", "*.gif")
    paths = []
    for e in exts:
        paths.extend(glob.glob(os.path.join(folder, e)))
    return paths


def file_md5(path: str) -> str:
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def ensure_pillow_image(path: str) -> Optional[Image.Image]:
    if not PIL_OK:
        return None
    try:
        with Image.open(path) as im:
            im.load()
            return im
    except (UnidentifiedImageError, OSError):
        return None


def exif_normalize_and_convert_jpg(path: str, out_path: str, quality: int = 92) -> bool:
    """Normalizes EXIF orientation and saves to .jpg"""
    if not PIL_OK:
        return False
    try:
        with Image.open(path) as im:
            im = ImageOps.exif_transpose(im)
            if im.mode in ("RGBA", "LA"):
                bg = Image.new("RGB", im.size, (255, 255, 255))
                bg.paste(im, mask=im.split()[-1])
                im = bg
            else:
                im = im.convert("RGB")
            im.save(out_path, "JPEG", optimize=True, quality=quality, progressive=True)
        return True
    except Exception:
        return False


def cv2_read_size(path: str) -> Tuple[int, int]:
    """Returns (w, h) or (0, 0) if unable to read"""
    try:
        img = cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_UNCHANGED)
        if img is None:
            return (0, 0)
        h, w = img.shape[:2]
        return (w, h)
    except Exception:
        return (0, 0)


def simple_dhash(image_path: str, hash_size: int = 8) -> Optional[int]:
    """Own dHash implementation (if no imagehash), returns int or None."""
    try:
        with Image.open(image_path) as img:
            img = img.convert("L").resize((hash_size + 1, hash_size), Image.Resampling.LANCZOS)
            diff = []
            for y in range(hash_size):
                for x in range(hash_size):
                    left = img.getpixel((x, y))
                    right = img.getpixel((x + 1, y))
                    diff.append(left > right)
            # Convert to int
            v = 0
            for b in diff:
                v = (v << 1) | int(b)
            return v
    except Exception:
        return None


def hamming_distance(a: int, b: int) -> int:
    return (a ^ b).bit_count()


# ------------------------- "is cat" filter (MobileNetV2) -------------------------
class CatFilter:
    def __init__(self, threshold: float = 0.20, disabled: bool = False, logger: Optional[logging.Logger] = None):
        self.threshold = threshold
        self.disabled = disabled or (not TF_OK)
        self.logger = logger
        self.model = None
        if self.disabled:
            if self.logger:
                self.logger.info("'is cat' filter disabled (TF_OK=%s).", TF_OK)
        else:
            try:
                self.model = MobileNetV2(weights="imagenet")
                if self.logger:
                    self.logger.info("Loaded MobileNetV2 model (ImageNet) for 'is cat' filter.")
            except Exception as e:
                self.disabled = True
                if self.logger:
                    self.logger.warning("Failed to load MobileNetV2: %s. 'is cat' filter disabled.", e)

    def is_cat(self, path: str) -> bool:
        if self.disabled or self.model is None:
            return True  # don't filter
        try:
            img = Image.open(path).convert("RGB").resize((224, 224), Image.Resampling.BILINEAR)
            x = np.array(img, dtype=np.float32)
            x = np.expand_dims(x, axis=0)
            x = preprocess_input(x)
            preds = self.model.predict(x, verbose=0)
            top = np.argmax(preds[0])
            prob = float(preds[0][top])
            # ImageNet: 281–285 — cat classes
            is_cat = (281 <= top <= 285) and (prob >= self.threshold)
            return bool(is_cat)
        except Exception:
            return False


# ------------------------------ Breed folder cleanup ------------------------------
@dataclass
class CleanStats:
    before: int = 0
    removed_small: int = 0
    removed_broken: int = 0
    removed_notcat: int = 0
    removed_dup_md5: int = 0
    removed_dup_phash: int = 0
    after: int = 0


def clean_breed_folder(
    folder: str,
    min_side: int,
    cat_filter: CatFilter,
    jpg_only: bool,
    keep_intermediate: bool,
    remove_near_dup: bool,
    logger: logging.Logger,
) -> CleanStats:

    stats = CleanStats()
    paths = list_images(folder)
    stats.before = len(paths)
    logger.info("Очистка %s: найдено %d файлов", folder, stats.before)

    # 1) удалить битые и слишком маленькие, привести к jpg (если нужно)
    kept_paths = []
    for p in paths:
        # Проверка Pillow — валидна ли картинка
        im_ok = ensure_pillow_image(p) if PIL_OK else None
        if im_ok is None and PIL_OK:
            try:
                os.remove(p)
                stats.removed_broken += 1
            except Exception:
                pass
            continue

        # Размер
        w, h = cv2_read_size(p)
        if w == 0 or h == 0 or min(w, h) < min_side:
            try:
                os.remove(p)
                stats.removed_small += 1
            except Exception:
                pass
            continue

        # Приведение к .jpg
        if jpg_only and PIL_OK:
            base, ext = os.path.splitext(p)
            out_jpg = base + ".jpg"
            if ext.lower() not in [".jpg", ".jpeg"] or not os.path.exists(out_jpg):
                ok = exif_normalize_and_convert_jpg(p, out_jpg, quality=92)
                if ok:
                    if not keep_intermediate:
                        try:
                            os.remove(p)
                        except Exception:
                            pass
                    p = out_jpg
                else:
                    # если не удалось конвертировать — пропускаем/удаляем
                    try:
                        os.remove(p)
                    except Exception:
                        pass
                    stats.removed_broken += 1
                    continue

        kept_paths.append(p)

    # 2) фильтр "is cat"
    filtered_paths = []
    for p in kept_paths:
        if cat_filter.is_cat(p):
            filtered_paths.append(p)
        else:
            try:
                os.remove(p)
            except Exception:
                pass
            stats.removed_notcat += 1

    # 3) удаление точных дубликатов (MD5)
    seen_md5: Dict[str, str] = {}
    md5_filtered = []
    for p in filtered_paths:
        try:
            h = file_md5(p)
        except Exception:
            try:
                os.remove(p)
            except Exception:
                pass
            stats.removed_broken += 1
            continue
        if h in seen_md5:
            try:
                os.remove(p)
            except Exception:
                pass
            stats.removed_dup_md5 += 1
        else:
            seen_md5[h] = p
            md5_filtered.append(p)

    # 4) удаление почти-дубликатов (перцептуальный хэш)
    final_paths = []
    if remove_near_dup and (PIL_OK or IMAGEHASH_OK):
        seen_hashes: List[Tuple[str, int]] = []
        for p in md5_filtered:
            try:
                if IMAGEHASH_OK:
                    with Image.open(p) as im:
                        ph = int(str(imagehash.phash(im, hash_size=16)), 16)
                else:
                    ph = simple_dhash(p, hash_size=16)
                    if ph is None:
                        # если не удалось получить хэш — считаем битым
                        try:
                            os.remove(p)
                        except Exception:
                            pass
                        stats.removed_broken += 1
                        continue
            except Exception:
                try:
                    os.remove(p)
                except Exception:
                    pass
                stats.removed_broken += 1
                continue

            is_dup = False
            for _, prev_h in seen_hashes:
                if hamming_distance(prev_h, ph) <= 6:  # порог близости
                    is_dup = True
                    break
            if is_dup:
                try:
                    os.remove(p)
                except Exception:
                    pass
                stats.removed_dup_phash += 1
            else:
                seen_hashes.append((p, ph))
                final_paths.append(p)
    else:
        final_paths = md5_filtered

    stats.after = len(final_paths)
    logger.info(
        "Очистка %s: было=%d, стало=%d (small=%d, broken=%d, notcat=%d, dup_md5=%d, dup_phash=%d)",
        folder, stats.before, stats.after, stats.removed_small, stats.removed_broken,
        stats.removed_notcat, stats.removed_dup_md5, stats.removed_dup_phash
    )
    return stats


# ------------------------------ Загрузка изображений ------------------------------
def crawl_breed(
    breed: str,
    out_dir: str,
    target_count: int,
    engine: str,
    max_total: int,
    logger: logging.Logger
):
    assert ICRAWLER_OK, "icrawler не установлен."
    breed_slug = slugify(breed)
    save_dir = os.path.join(out_dir, breed_slug)
    os.makedirs(save_dir, exist_ok=True)

    # если уже много файлов — пропустим загрузку
    current = len(list_images(save_dir))
    if current >= target_count:
        logger.info("⏭️  %s — уже %d файлов (>= %d). Пропуск загрузки.", breed, current, target_count)
        return

    left = min(max_total, target_count - current)
    if left <= 0:
        return

    logger.info("🔎 Загрузка %d изображений для '%s' → %s (engine=%s)",
                left, breed, save_dir, engine)

    def _crawl_google(n):
        crawler = GoogleImageCrawler(
            storage={"root_dir": save_dir},
            downloader_threads=4,
            parser_threads=2
        )
        crawler.crawl(
            keyword=breed,
            max_num=n,
            min_size=(256, 256),
            filters={"type": "photo"},
            file_idx_offset=0
        )

    def _crawl_bing(n):
        crawler = BingImageCrawler(
            storage={"root_dir": save_dir},
            downloader_threads=4,
            parser_threads=2
        )
        crawler.crawl(
            keyword=breed,
            max_num=n,
            filters={"type": "photo"}
        )

    ok = False
    if engine in ("auto", "google"):
        try:
            _crawl_google(left)
            ok = True
        except Exception as e:
            logger.warning("GoogleImageCrawler ошибка для '%s': %s", breed, e)

    if not ok and engine in ("auto", "bing"):
        try:
            _crawl_bing(left)
            ok = True
        except Exception as e:
            logger.warning("BingImageCrawler ошибка для '%s': %s", breed, e)

    if not ok:
        logger.error("❌ Не удалось загрузить изображения для '%s' ни через Google, ни через Bing.", breed)
    else:
        new_total = len(list_images(save_dir))
        logger.info("✅ Загрузка завершена для '%s'. Было=%d, стало=%d", breed, current, new_total)


# ------------------------------ Manifest и отчёты ------------------------------
def write_manifest(out_dir: str, records: List[Dict[str, str]], logger: logging.Logger):
    man_path = os.path.join(out_dir, "manifest.csv")
    fieldnames = ["breed", "breed_slug", "path", "width", "height", "md5"]
    with open(man_path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in records:
            w.writerow(r)
    logger.info("💾 manifest.csv записан: %s (строк: %d)", man_path, len(records))


def scan_and_manifest(out_dir: str, min_side: int, logger: logging.Logger) -> List[Dict[str, str]]:
    records: List[Dict[str, str]] = []
    for breed in CAT_BREEDS:
        breed_slug = slugify(breed)
        folder = os.path.join(out_dir, breed_slug)
        if not os.path.isdir(folder):
            continue
        for p in list_images(folder):
            w, h = cv2_read_size(p)
            if min(w, h) < min_side:
                continue
            try:
                md5 = file_md5(p)
            except Exception:
                continue
            records.append({
                "breed": breed,
                "breed_slug": breed_slug,
                "path": os.path.relpath(p, out_dir),
                "width": str(w),
                "height": str(h),
                "md5": md5
            })
    return records


# -------------------------------- MAIN --------------------------------
def main():
    args = parse_args()
    os.makedirs(args.out, exist_ok=True)
    logger = make_logger(args.out)

    logger.info("Параметры: %s", vars(args))
    if not ICRAWLER_OK:
        logger.error("icrawler не установлен. Установите: pip install icrawler")
        sys.exit(1)

    # Инициализация фильтра "is cat"
    cat_filter = CatFilter(threshold=args.cat_threshold, disabled=args.no_is_cat, logger=logger)

    # Возможное ограничение числа пород (для отладки)
    breeds = CAT_BREEDS[: args.limit_breeds] if args.limit_breeds > 0 else CAT_BREEDS
    logger.info("Всего пород к обработке: %d", len(breeds))

    # Главный цикл
    for idx, breed in enumerate(breeds, 1):
        try:
            breed_slug = slugify(breed)
            breed_dir = os.path.join(args.out, breed_slug)
            os.makedirs(breed_dir, exist_ok=True)

            # Пропуск загрузки, если уже есть достаточно
            existing = len(list_images(breed_dir))
            if existing < args.images_per_breed:
                crawl_breed(
                    breed=breed,
                    out_dir=args.out,
                    target_count=args.images_per_breed,
                    engine=args.engine,
                    max_total=args.max_total_per_breed,
                    logger=logger
                )
            else:
                logger.info("⏭️  %s — уже %d файлов. Пропуск загрузки.", breed, existing)

            # Очистка
            logger.info("🧹 Очистка изображений для '%s'...", breed)
            stats = clean_breed_folder(
                folder=breed_dir,
                min_side=args.min_size,
                cat_filter=cat_filter,
                jpg_only=args.jpg_only,
                keep_intermediate=args.keep_intermediate,
                remove_near_dup=not args.no_near_dup,
                logger=logger
            )

            # Сон между породами
            if args.sleep > 0:
                time.sleep(args.sleep)

            logger.info("[%d/%d] '%s' готово. Итоговых файлов: %d",
                        idx, len(breeds), breed, len(list_images(breed_dir)))

        except Exception as e:
            logger.error("Ошибка при обработке '%s': %s", breed, e)
            logger.error(traceback.format_exc())
            if args.sleep > 0:
                time.sleep(args.sleep)

    # Соберём manifest и сохраним
    logger.info("📦 Сканирование и формирование manifest.csv ...")
    manifest = scan_and_manifest(args.out, args.min_size, logger)
    write_manifest(args.out, manifest, logger)

    # Короткий JSON отчёт
    report = {
        "total_breeds": len(breeds),
        "total_images": len(manifest),
        "min_size": args.min_size,
        "jpg_only": args.jpg_only,
        "is_cat_filter_enabled": not args.no_is_cat and TF_OK,
        "near_dup_removal": not args.no_near_dup,
        "engine": args.engine,
        "images_per_breed_target": args.images_per_breed
    }
    with open(os.path.join(args.out, "report.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    logger.info("💡 Отчёт сохранён: %s", os.path.join(args.out, "report.json"))
    logger.info("✅ Готово. Датасет лежит в: %s", args.out)


if __name__ == "__main__":
    main()
