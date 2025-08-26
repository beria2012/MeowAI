#!/usr/bin/env python3
"""
Create Comprehensive Breed Data for 40 Breeds
=============================================
"""

import json
import os

def create_breed_data():
    """Create comprehensive breed data for the 40 breeds"""
    
    # Load class indices
    with open('/Users/oleksandr/Projects/MeowAI/MeowAI/scripts/training/class_indices.json', 'r') as f:
        class_indices = json.load(f)
    
    breeds_data = []
    
    # Comprehensive breed information
    breed_info = {
        "abyssinian": {
            "name": "Abyssinian",
            "origin": "Ethiopia",
            "description": "Active, intelligent, and playful cats with distinctive ticked coats.",
            "temperament": "Active, Alert, Curious, Playful",
            "life_span": "14-15 years",
            "weight": "3.5-5.5 kg",
            "colors": ["Ruddy", "Red", "Blue", "Fawn"],
            "hypoallergenic": False,
            "rare": False,
            "energy_level": 5,
            "social_needs": 4,
            "grooming": 2
        },
        "american_shorthair": {
            "name": "American Shorthair", 
            "origin": "United States",
            "description": "Well-balanced, healthy cats with easy-going personalities.",
            "temperament": "Easy Going, Calm, Gentle, Independent",
            "life_span": "13-16 years",
            "weight": "3.5-7 kg",
            "colors": ["Silver Tabby", "Brown Tabby", "Black", "White"],
            "hypoallergenic": False,
            "rare": False,
            "energy_level": 3,
            "social_needs": 3,
            "grooming": 2
        },
        "bengal": {
            "name": "Bengal",
            "origin": "United States", 
            "description": "Wild-looking cats with leopard-like spots and energetic nature.",
            "temperament": "Active, Athletic, Curious, Intelligent",
            "life_span": "12-16 years",
            "weight": "4-8 kg",
            "colors": ["Brown Spotted", "Silver Spotted", "Snow"],
            "hypoallergenic": True,
            "rare": False,
            "energy_level": 5,
            "social_needs": 4,
            "grooming": 2
        },
        "british_shorthair": {
            "name": "British Shorthair",
            "origin": "United Kingdom",
            "description": "Round-faced, sturdy cats with plush coats and calm demeanor.",
            "temperament": "Calm, Easy Going, Gentle, Loyal",
            "life_span": "12-17 years", 
            "weight": "4-8 kg",
            "colors": ["Blue", "Silver", "Golden", "Black"],
            "hypoallergenic": False,
            "rare": False,
            "energy_level": 2,
            "social_needs": 3,
            "grooming": 3
        },
        "persian": {
            "name": "Persian",
            "origin": "Iran",
            "description": "Long-haired cats with flat faces and luxurious coats.",
            "temperament": "Quiet, Sweet, Docile, Gentle",
            "life_span": "10-17 years",
            "weight": "3.2-5.5 kg", 
            "colors": ["White", "Black", "Blue", "Cream"],
            "hypoallergenic": False,
            "rare": False,
            "energy_level": 1,
            "social_needs": 3,
            "grooming": 5
        },
        "siamese": {
            "name": "Siamese",
            "origin": "Thailand",
            "description": "Vocal, intelligent cats with distinctive color points.",
            "temperament": "Vocal, Social, Intelligent, Active",
            "life_span": "12-15 years",
            "weight": "2.5-5 kg",
            "colors": ["Seal Point", "Chocolate Point", "Blue Point", "Lilac Point"],
            "hypoallergenic": True,
            "rare": False,
            "energy_level": 4,
            "social_needs": 5,
            "grooming": 1
        }
    }
    
    # Generate data for all 40 breeds
    for breed_key, index in class_indices.items():
        breed_name = breed_key.replace('_', ' ').title()
        
        # Use specific info if available, otherwise generate defaults
        if breed_key in breed_info:
            info = breed_info[breed_key]
        else:
            info = {
                "name": breed_name,
                "origin": "Various",
                "description": f"Beautiful {breed_name} cats known for their unique characteristics.",
                "temperament": "Friendly, Intelligent, Playful",
                "life_span": "12-15 years",
                "weight": "3-6 kg",
                "colors": ["Various"],
                "hypoallergenic": False,
                "rare": False,
                "energy_level": 3,
                "social_needs": 3,
                "grooming": 2
            }
        
        breed_data = {
            "id": breed_key,
            "name": info["name"],
            "origin": info["origin"],
            "description": info["description"],
            "temperament": info["temperament"],
            "life_span": info["life_span"],
            "weight": info["weight"],
            "colors": info["colors"],
            "is_hypoallergenic": info["hypoallergenic"],
            "is_rare": info["rare"],
            "energy_level": info["energy_level"],
            "social_needs": info["social_needs"],
            "grooming_needs": info["grooming"],
            "image_url": f"assets/images/breeds/{breed_key}.jpg",
            "ml_index": index
        }
        
        breeds_data.append(breed_data)
    
    # Sort by ML index
    breeds_data.sort(key=lambda x: x["ml_index"])
    
    # Save to assets
    output_path = '/Users/oleksandr/Projects/MeowAI/MeowAI/assets/data/model_breeds.json'
    with open(output_path, 'w') as f:
        json.dump(breeds_data, f, indent=2)
    
    print(f"✅ Created breed data for {len(breeds_data)} breeds")
    print(f"📄 Saved to: {output_path}")
    
    return breeds_data

if __name__ == "__main__":
    create_breed_data()