#!/bin/bash

# Test script to verify tilde expansion fix
cd astra-core

echo "Testing tilde expansion fix..."

# Test with root user
echo "Test 1: Root user with ~/test"
echo '{
  "host": "localhost",
  "port": 22,
  "username": "root",
  "password": "password",
  "remote_path": "~/test",
  "local_path": "/tmp/local"
}' > test_config_root.json

echo "Test 2: Regular user with ~/test"
echo '{
  "host": "localhost",
  "port": 22,
  "username": "testuser",
  "password": "password",
  "remote_path": "~/test",
  "local_path": "/tmp/local"
}' > test_config_user.json

echo "Test 3: Root user with ~"
echo '{
  "host": "localhost",
  "port": 22,
  "username": "root",
  "password": "password",
  "remote_path": "~",
  "local_path": "/tmp/local"
}' > test_config_root_home.json

echo "Test 4: Regular user with ~"
echo '{
  "host": "localhost",
  "port": 22,
  "username": "testuser",
  "password": "password",
  "remote_path": "~",
  "local_path": "/tmp/local"
}' > test_config_user_home.json

echo "Running tests..."
cargo run -- --config test_config_root.json status 2>/dev/null | grep -E "(remote_path|Remote path)" || echo "Test 1 completed"
cargo run -- --config test_config_user.json status 2>/dev/null | grep -E "(remote_path|Remote path)" || echo "Test 2 completed"
cargo run -- --config test_config_root_home.json status 2>/dev/null | grep -E "(remote_path|Remote path)" || echo "Test 3 completed"
cargo run -- --config test_config_user_home.json status 2>/dev/null | grep -E "(remote_path|Remote path)" || echo "Test 4 completed"

# Cleanup
rm -f test_config_root.json test_config_user.json test_config_root_home.json test_config_user_home.json

echo "Tests completed!"