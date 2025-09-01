#!/bin/bash

# Test script for internationalization functionality
# This script demonstrates the multi-language support in Astra.nvim

echo "🌍 Testing Astra.nvim Internationalization"
echo "=========================================="

# Test different language settings
test_language() {
    local lang=$1
    local lang_name=$2
    
    echo ""
    echo "🔤 Testing language: $lang_name ($lang)"
    echo "----------------------------------------"
    
    # Set environment variable for language
    export ASTRA_LANGUAGE=$lang
    
    # Test version command
    echo "📋 Testing version command:"
    CARGO_HOME=/home/ethan/.cargo PATH=/home/ethan/.cargo/bin:$PATH cargo run --manifest-path /home/ethan/work/rust/astra.nvim/astra-core/Cargo.toml -- version 2>/dev/null
    echo ""
    
    # Test config test command
    echo "🔍 Testing config test command:"
    CARGO_HOME=/home/ethan/.cargo PATH=/home/ethan/.cargo/bin:$PATH cargo run --manifest-path /home/ethan/work/rust/astra.nvim/astra-core/Cargo.toml -- config-test 2>/dev/null
    echo ""
    
    # Test check update command
    echo "🔄 Testing check update command:"
    CARGO_HOME=/home/ethan/.cargo PATH=/home/ethan/.cargo/bin:$PATH timeout 5s cargo run --manifest-path /home/ethan/work/rust/astra.nvim/astra-core/Cargo.toml -- check-update 2>/dev/null || true
    echo ""
    
    # Clean up
    unset ASTRA_LANGUAGE
}

# Test supported languages
test_language "en" "English"
test_language "zh" "Chinese"
test_language "ja" "Japanese"
test_language "ko" "Korean"
test_language "es" "Spanish"
test_language "fr" "French"
test_language "de" "German"
test_language "ru" "Russian"

echo ""
echo "✅ Internationalization testing completed!"
echo ""
echo "📝 Note: Some commands may show error messages about missing configuration files."
echo "   This is expected behavior - the important part is that the messages are"
echo "   displayed in the correct language."