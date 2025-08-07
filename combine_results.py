#!/usr/bin/env python3
"""
Combine timing results from multiple architectures into a single CSV file.
Usage: 
  python3 combine_results.py
  
Or with venv:
  source venv/bin/activate && python3 combine_results.py
"""

import pandas as pd
import os
import sys
from datetime import datetime

def combine_architecture_results():
    """Combine timing results from amd64, arm64, and riscv64 into one file."""
    
    # Define the architecture files to combine
    arch_files = {
        'amd64': 'amd64-timing_results.csv',
        'arm64': 'arm64-timing_results.csv', 
        'riscv64': 'riscv64-timing_results.csv'
    }
    
    combined_data = []
    found_files = []
    
    print("🔍 Looking for architecture-specific timing files...")
    
    for arch, filename in arch_files.items():
        if os.path.exists(filename):
            print(f"✅ Found: {filename}")
            try:
                # Read the CSV file
                df = pd.read_csv(filename, quoting=1)
                
                # Add architecture column
                df['Architecture'] = arch.upper()
                
                # Reorder columns to have Architecture near the beginning
                cols = df.columns.tolist()
                # Move Architecture to be the second column (after Runtime)
                if 'Runtime' in cols:
                    runtime_idx = cols.index('Runtime')
                    cols.insert(runtime_idx + 1, cols.pop(cols.index('Architecture')))
                else:
                    # If no Runtime column, put Architecture first
                    cols.insert(0, cols.pop(cols.index('Architecture')))
                df = df[cols]
                
                combined_data.append(df)
                found_files.append(filename)
                
                print(f"   📊 Loaded {len(df)} measurements from {arch.upper()}")
                
            except Exception as e:
                print(f"❌ Error reading {filename}: {e}")
        else:
            print(f"⚠️  Not found: {filename}")
    
    if not combined_data:
        print("❌ No valid timing files found!")
        print(f"   Expected files: {', '.join(arch_files.values())}")
        return False
    
    # Combine all dataframes
    print(f"\n🔄 Combining data from {len(combined_data)} architecture(s)...")
    combined_df = pd.concat(combined_data, ignore_index=True)
    
    # Generate output filename with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"combined_timing_results_{timestamp}.csv"
    
    # Save combined results
    combined_df.to_csv(output_file, index=False)
    
    print(f"✅ Combined results saved to: {output_file}")
    print(f"📊 Total measurements: {len(combined_df)}")
    
    # Show summary statistics
    print(f"\n📈 Data Summary:")
    print("=" * 50)
    
    # Summary by architecture
    arch_summary = combined_df.groupby('Architecture').size()
    print("Measurements per architecture:")
    for arch, count in arch_summary.items():
        print(f"  {arch}: {count}")
    
    # Summary by runtime and architecture
    if 'Runtime' in combined_df.columns:
        print(f"\nRuntime distribution:")
        runtime_arch_summary = combined_df.groupby(['Architecture', 'Runtime']).size().unstack(fill_value=0)
        print(runtime_arch_summary.to_string())
    
    # Summary by image type and architecture
    if 'Image' in combined_df.columns:
        combined_df['Image_Type'] = combined_df['Image'].apply(lambda x: 'WASM' if 'wasm' in str(x).lower() else 'Native')
        print(f"\nImage type distribution:")
        image_arch_summary = combined_df.groupby(['Architecture', 'Image_Type']).size().unstack(fill_value=0)
        print(image_arch_summary.to_string())
    
    # WASM runtime distribution (if applicable)
    if 'WASM_Runtime' in combined_df.columns:
        wasm_data = combined_df[combined_df['WASM_Runtime'] != 'N/A']
        if not wasm_data.empty:
            print(f"\nWASM runtime distribution:")
            wasm_runtime_summary = wasm_data.groupby(['Architecture', 'WASM_Runtime']).size().unstack(fill_value=0)
            print(wasm_runtime_summary.to_string())
    
    # Show column information
    print(f"\n📋 Combined dataset columns:")
    for i, col in enumerate(combined_df.columns, 1):
        print(f"  {i:2d}. {col}")
    
    print(f"\n💾 Files processed: {', '.join(found_files)}")
    print(f"🎯 Output file: {output_file}")
    
    return True

if __name__ == "__main__":
    print("🚀 Multi-Architecture Timing Results Combiner")
    print("=" * 50)
    
    success = combine_architecture_results()
    
    if success:
        print("\n🎉 Successfully combined architecture timing results!")
        print("\nNext steps:")
        print("1. Use the combined CSV with the Jupyter notebook for cross-architecture analysis")
        print("2. Run: source venv/bin/activate && jupyter notebook analyze_multiarch_results.ipynb")
        print("   (Or: jupyter notebook analyze_multiarch_results.ipynb if venv already active)")
        print("3. The notebook will automatically detect the architecture column for comparison")
    else:
        print("\n❌ Failed to combine results. Please check that the timing files exist.")
        sys.exit(1)