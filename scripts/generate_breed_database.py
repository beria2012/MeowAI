#!/usr/bin/env python3
"""
Script to generate comprehensive cat breed database for all 223 breeds.
This will create detailed breed information for use in the MeowAI app.
"""

import json
import re
from typing import Dict, List, Any

def clean_breed_name(name: str) -> str:
    """Convert ML label to clean breed name."""
    # Replace underscores with spaces
    name = name.replace('_', ' ')
    
    # Handle special cases
    special_cases = {
        'Li Hua': 'Chinese Li Hua',
        'Dragon Li': 'Dragon Li',
        'XiaoMao': 'Xiao Mao',
        'Van Kedisi': 'Turkish Van Kedisi',
        'Qi Mao': 'Qi Mao',
        'Xian Mao': 'Xian Mao',
        'Kucing Malaysia': 'Malaysian Cat'
    }
    
    if name in special_cases:
        return special_cases[name]
    
    # Capitalize each word
    return ' '.join(word.capitalize() for word in name.split())

def get_breed_origin(breed_name: str) -> str:
    """Determine breed origin based on name patterns."""
    name_lower = breed_name.lower()
    
    origins = {
        'american': 'United States',
        'british': 'United Kingdom', 
        'russian': 'Russia',
        'persian': 'Iran',
        'siamese': 'Thailand',
        'thai': 'Thailand',
        'chinese': 'China',
        'japanese': 'Japan',
        'turkish': 'Turkey',
        'norwegian': 'Norway',
        'maine': 'United States',
        'california': 'United States',
        'himalayan': 'United States',
        'burmese': 'Myanmar',
        'egyptian': 'Egypt',
        'european': 'Europe',
        'siberian': 'Russia',
        'australian': 'Australia',
        'canadian': 'Canada',
        'korean': 'South Korea',
        'mongolian': 'Mongolia',
        'tibetan': 'Tibet',
        'arabian': 'Arabian Peninsula',
        'scandinavian': 'Scandinavia',
        'mediterranean': 'Mediterranean Region',
        'alpine': 'Alps Region',
        'bavarian': 'Germany',
        'galician': 'Spain',
        'hungarian': 'Hungary',
        'orkney': 'Scotland',
        'shetland': 'Scotland',
        'cyprus': 'Cyprus',
        'isle of man': 'Isle of Man',
        'tasmania': 'Australia',
        'queensland': 'Australia',
        'lanka': 'Sri Lanka',
        'nicobar': 'India',
        'ryukyu': 'Japan',
        'kucing malaysia': 'Malaysia'
    }
    
    for pattern, origin in origins.items():
        if pattern in name_lower:
            return origin
    
    return 'Unknown'

def get_breed_characteristics(breed_name: str) -> List[str]:
    """Generate characteristics based on breed name and type."""
    name_lower = breed_name.lower()
    characteristics = []
    
    # Coat length
    if any(x in name_lower for x in ['longhair', 'long hair']):
        characteristics.append('Long-haired')
    elif any(x in name_lower for x in ['shorthair', 'short hair']):
        characteristics.append('Short-haired')
    
    # Special features
    if 'rex' in name_lower:
        characteristics.append('Curly coat')
    if 'bobtail' in name_lower:
        characteristics.append('Short tail')
    if 'fold' in name_lower:
        characteristics.append('Folded ears')
    if 'curl' in name_lower:
        characteristics.append('Curled ears')
    if 'sphynx' in name_lower or 'hairless' in name_lower:
        characteristics.append('Hairless')
    if 'munchkin' in name_lower or 'dwarf' in name_lower:
        characteristics.append('Short legs')
    if 'polydactyl' in name_lower:
        characteristics.append('Extra toes')
    if 'point' in name_lower:
        characteristics.append('Color points')
    
    # Size indicators
    if any(x in name_lower for x in ['maine coon', 'ragdoll', 'norwegian forest']):
        characteristics.append('Large size')
    elif any(x in name_lower for x in ['singapura', 'munchkin']):
        characteristics.append('Small size')
    
    # Add some defaults if none found
    if not characteristics:
        characteristics = ['Unique appearance', 'Distinctive features']
    
    return characteristics

def get_temperament(breed_name: str) -> str:
    """Generate temperament based on breed type."""
    name_lower = breed_name.lower()
    
    temperaments = {
        'persian': 'Calm, Gentle, Sweet',
        'siamese': 'Active, Vocal, Social',
        'maine coon': 'Gentle, Friendly, Intelligent',
        'british': 'Calm, Easy-going, Loyal',
        'ragdoll': 'Docile, Placid, Quiet',
        'bengal': 'Active, Playful, Intelligent',
        'russian': 'Gentle, Quiet, Loyal',
        'sphynx': 'Energetic, Social, Mischievous',
        'abyssinian': 'Active, Playful, Intelligent',
        'american': 'Friendly, Adaptable, Easy-going',
        'norwegian': 'Gentle, Patient, Friendly',
        'scottish': 'Sweet, Calm, Adaptable',
        'burmese': 'Affectionate, Social, Playful',
        'oriental': 'Active, Vocal, Intelligent',
        'turkish': 'Energetic, Playful, Intelligent'
    }
    
    for pattern, temp in temperaments.items():
        if pattern in name_lower:
            return temp
    
    return 'Friendly, Intelligent, Adaptable'

def generate_breed_data(breed_label: str) -> Dict[str, Any]:
    """Generate comprehensive breed data from ML label."""
    clean_name = clean_breed_name(breed_label)
    
    return {
        "id": breed_label.lower(),
        "name": clean_name,
        "description": f"The {clean_name} is a distinctive cat breed known for its unique characteristics and beautiful appearance. This breed has developed special traits that make it stand out among feline companions.",
        "origin": get_breed_origin(clean_name),
        "temperament": get_temperament(clean_name),
        "lifeSpan": "12-16 years",
        "weight": "3.5-6.0 kg",
        "imageUrl": f"assets/images/breeds/{breed_label.lower()}.jpg",
        "characteristics": get_breed_characteristics(clean_name),
        "history": f"The {clean_name} has a rich history and has been carefully bred to maintain its distinctive characteristics. This breed represents the beauty and diversity found in the feline world.",
        "energyLevel": 3,
        "sheddingLevel": 3,
        "socialNeeds": 3,
        "groomingNeeds": 2,
        "isHypoallergenic": breed_label.lower() in ['sphynx', 'devon_rex', 'cornish_rex', 'russian_blue', 'bengal', 'balinese', 'oriental_shorthair', 'javanese'],
        "isRare": 'hybrid' in breed_label.lower() or any(x in breed_label.lower() for x in ['lykoi', 'peterbald', 'donskoy', 'ukrainian_levkoy', 'bambino', 'dwelf', 'elf', 'minskin'])
    }

def main():
    """Generate the complete breed database."""
    print("Generating comprehensive cat breed database...")
    
    # Read labels from file
    try:
        with open('../assets/models/labels.txt', 'r') as f:
            labels = [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print("Error: labels.txt not found. Please ensure the file exists.")
        return
    
    print(f"Found {len(labels)} breed labels")
    
    # Generate breed data
    breeds_data = []
    for label in labels:
        if label:  # Skip empty lines
            breed_data = generate_breed_data(label)
            breeds_data.append(breed_data)
    
    # Save to JSON file
    output_file = '../assets/data/comprehensive_cat_breeds.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(breeds_data, f, indent=2, ensure_ascii=False)
    
    print(f"Generated database with {len(breeds_data)} breeds")
    print(f"Saved to: {output_file}")
    
    # Print some examples
    print("\nSample breeds generated:")
    for i, breed in enumerate(breeds_data[:5]):
        print(f"  {i+1}. {breed['name']} ({breed['origin']})")

if __name__ == "__main__":
    main()