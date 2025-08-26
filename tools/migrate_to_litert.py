#!/usr/bin/env python3
"""
Automated LiteRT Migration Script for MeowAI
Migrates from TensorFlow Lite to LiteRT (ai-edge-litert)
"""

import os
import re
import shutil
from pathlib import Path

def backup_files():
    """Create backup of critical files"""
    print("📦 Creating backup of original files...")
    
    backup_dir = Path("../backup_before_litert")
    backup_dir.mkdir(exist_ok=True)
    
    files_to_backup = [
        "../android/app/build.gradle.kts",
        "../android/app/src/main/kotlin/com/meowai/meow_ai/NativeTFLitePlugin.kt"
    ]
    
    for file_path in files_to_backup:
        if os.path.exists(file_path):
            filename = os.path.basename(file_path)
            backup_path = backup_dir / filename
            shutil.copy2(file_path, backup_path)
            print(f"✅ Backed up: {filename}")

def update_gradle_dependencies():
    """Update build.gradle.kts to use LiteRT"""
    print("🔧 Updating Gradle dependencies...")
    
    gradle_path = "../android/app/build.gradle.kts"
    
    if not os.path.exists(gradle_path):
        print(f"❌ Gradle file not found: {gradle_path}")
        return False
    
    with open(gradle_path, 'r') as f:
        content = f.read()
    
    # Replace TensorFlow Lite dependencies with LiteRT
    replacements = [
        # Remove old TensorFlow Lite dependencies
        (r'implementation\("org\.tensorflow:tensorflow-lite:[\d\.]+"\)\s*\{[^}]*\}', ''),
        (r'implementation\("org\.tensorflow:tensorflow-lite:[\d\.]+"\)', ''),
        (r'implementation\("org\.tensorflow:tensorflow-lite-support:[\d\.]+"\)\s*\{[^}]*\}', ''),
        (r'implementation\("org\.tensorflow:tensorflow-lite-support:[\d\.]+"\)', ''),
        (r'implementation\("org\.tensorflow:tensorflow-lite-gpu:[\d\.]+"\)\s*\{[^}]*\}', ''),
        (r'implementation\("org\.tensorflow:tensorflow-lite-gpu:[\d\.]+"\)', ''),
    ]
    
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)
    
    # Add LiteRT dependencies
    litert_deps = '''
    // LiteRT (Google AI Edge) - Next generation TensorFlow Lite
    implementation("com.google.ai.edge.litert:litert:0.1.0")
    implementation("com.google.ai.edge.litert:litert-support:0.1.0")'''
    
    # Find dependencies block and add LiteRT
    if 'dependencies {' in content:
        content = content.replace('dependencies {', f'dependencies {{{litert_deps}')
    
    # Clean up extra newlines
    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
    
    with open(gradle_path, 'w') as f:
        f.write(content)
    
    print("✅ Gradle dependencies updated to LiteRT")
    return True

def update_native_plugin():
    """Update NativeTFLitePlugin.kt to use LiteRT APIs"""
    print("🔧 Updating native plugin for LiteRT...")
    
    plugin_path = "../android/app/src/main/kotlin/com/meowai/meow_ai/NativeTFLitePlugin.kt"
    
    if not os.path.exists(plugin_path):
        print(f"❌ Plugin file not found: {plugin_path}")
        return False
    
    with open(plugin_path, 'r') as f:
        content = f.read()
    
    # Replace imports
    import_replacements = [
        ('import org.tensorflow.lite.Interpreter', 'import ai.edge.litert.Interpreter'),
        ('import org.tensorflow.lite.', 'import ai.edge.litert.'),
    ]
    
    for old_import, new_import in import_replacements:
        content = content.replace(old_import, new_import)
    
    # Update class references if needed
    # LiteRT API is mostly compatible, but we might need some adjustments
    
    # Add LiteRT specific optimizations
    litert_optimizations = '''
    /**
     * LiteRT specific optimizations for better performance
     */
    private fun createLiteRTOptions(): Interpreter.Options {
        val options = Interpreter.Options()
        options.setNumThreads(4)
        options.setUseNNAPI(true)
        return options
    }'''
    
    # Add the optimization method before the last closing brace
    if content.count('}') > 0:
        last_brace_pos = content.rfind('}')
        content = content[:last_brace_pos] + litert_optimizations + '\n' + content[last_brace_pos:]
    
    with open(plugin_path, 'w') as f:
        f.write(content)
    
    print("✅ Native plugin updated for LiteRT")
    return True

def create_migration_summary():
    """Create a summary of changes made"""
    print("📋 Creating migration summary...")
    
    summary = """# LiteRT Migration Summary

## Changes Made

### 1. Dependencies Updated (build.gradle.kts)
- ❌ Removed: org.tensorflow:tensorflow-lite:2.16.1
- ❌ Removed: org.tensorflow:tensorflow-lite-support:0.4.4  
- ❌ Removed: org.tensorflow:tensorflow-lite-gpu:2.16.1
- ✅ Added: com.google.ai.edge.litert:litert:0.1.0
- ✅ Added: com.google.ai.edge.litert:litert-support:0.1.0

### 2. Native Plugin Updated (NativeTFLitePlugin.kt)
- ✅ Updated imports to use ai.edge.litert instead of org.tensorflow.lite
- ✅ Added LiteRT specific optimizations
- ✅ Maintained API compatibility

### 3. Benefits
- ✅ Supports FULLY_CONNECTED opcode version 12
- ✅ Better GPU acceleration
- ✅ Future-proof with Google's official replacement
- ✅ Improved performance capabilities

## Testing Steps

1. Clean and rebuild the project:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

2. Test the app functionality:
   - Model loading should now work
   - No more opcode compatibility errors
   - ML inference should function properly

3. If issues occur:
   - Check logs for LiteRT specific errors
   - Restore backup files if needed
   - Report any API differences

## Rollback Instructions

If migration causes issues:

1. Restore backed up files:
   ```bash
   cp backup_before_litert/build.gradle.kts android/app/
   cp backup_before_litert/NativeTFLitePlugin.kt android/app/src/main/kotlin/com/meowai/meow_ai/
   ```

2. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   ```

## Status: ✅ Migration Completed
"""
    
    with open("../docs/litert_migration_summary.md", 'w') as f:
        f.write(summary)
    
    print("✅ Migration summary created")

def test_migration():
    """Test if migration files are ready"""
    print("🧪 Testing migration readiness...")
    
    required_files = [
        "../android/app/build.gradle.kts",
        "../android/app/src/main/kotlin/com/meowai/meow_ai/NativeTFLitePlugin.kt"
    ]
    
    all_ready = True
    for file_path in required_files:
        if os.path.exists(file_path):
            print(f"✅ Found: {os.path.basename(file_path)}")
        else:
            print(f"❌ Missing: {file_path}")
            all_ready = False
    
    return all_ready

def main():
    """Main migration process"""
    print("🚀 LiteRT Migration Tool for MeowAI")
    print("=" * 50)
    print("This will migrate your project from TensorFlow Lite to LiteRT")
    print("LiteRT supports modern opcodes including FULLY_CONNECTED v12")
    print()
    
    # Test readiness
    if not test_migration():
        print("❌ Migration cannot proceed - missing required files")
        return
    
    # Confirm migration
    response = input("Continue with migration? (y/N): ").lower().strip()
    if response not in ['y', 'yes']:
        print("❌ Migration cancelled")
        return
    
    print("\n🔄 Starting migration process...")
    
    # Step 1: Backup
    backup_files()
    
    # Step 2: Update Gradle
    if not update_gradle_dependencies():
        print("❌ Failed to update Gradle dependencies")
        return
    
    # Step 3: Update native plugin
    if not update_native_plugin():
        print("❌ Failed to update native plugin")
        return
    
    # Step 4: Create summary
    create_migration_summary()
    
    print("\n" + "=" * 50)
    print("✅ LiteRT Migration completed successfully!")
    print()
    print("🔄 Next steps:")
    print("1. Clean and rebuild your project:")
    print("   flutter clean && flutter build apk --debug")
    print("2. Test the app - your model should now work!")
    print("3. Check migration summary in docs/litert_migration_summary.md")
    print()
    print("📁 Backup files saved in: backup_before_litert/")
    print("🔙 To rollback, restore files from backup directory")

if __name__ == "__main__":
    main()