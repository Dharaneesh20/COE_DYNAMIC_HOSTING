#!/usr/bin/env python3
"""
Test script for AWS Cloud Storage Application
Run this to verify the application is working correctly
"""

import requests
import sys
import time

def test_application(base_url="http://localhost:5000"):
    """Test the Flask application endpoints"""
    
    print(f"Testing AWS Cloud Storage Application at {base_url}")
    print("=" * 50)
    
    tests_passed = 0
    total_tests = 0
    
    # Test 1: Home page redirect
    total_tests += 1
    try:
        response = requests.get(base_url, allow_redirects=False)
        if response.status_code in [302, 301]:
            print("✓ Home page redirect works")
            tests_passed += 1
        else:
            print(f"✗ Home page redirect failed: {response.status_code}")
    except Exception as e:
        print(f"✗ Home page test failed: {e}")
    
    # Test 2: Login page
    total_tests += 1
    try:
        response = requests.get(f"{base_url}/login")
        if response.status_code == 200 and "Login" in response.text:
            print("✓ Login page loads correctly")
            tests_passed += 1
        else:
            print(f"✗ Login page failed: {response.status_code}")
    except Exception as e:
        print(f"✗ Login page test failed: {e}")
    
    # Test 3: Register page
    total_tests += 1
    try:
        response = requests.get(f"{base_url}/register")
        if response.status_code == 200 and "Register" in response.text:
            print("✓ Register page loads correctly")
            tests_passed += 1
        else:
            print(f"✗ Register page failed: {response.status_code}")
    except Exception as e:
        print(f"✗ Register page test failed: {e}")
    
    # Test 4: Pricing page
    total_tests += 1
    try:
        response = requests.get(f"{base_url}/pricing")
        if response.status_code == 200 and "Pricing" in response.text:
            print("✓ Pricing page loads correctly")
            tests_passed += 1
        else:
            print(f"✗ Pricing page failed: {response.status_code}")
    except Exception as e:
        print(f"✗ Pricing page test failed: {e}")
    
    # Test 5: Dashboard redirect (should redirect to login)
    total_tests += 1
    try:
        response = requests.get(f"{base_url}/dashboard", allow_redirects=False)
        if response.status_code in [302, 301]:
            print("✓ Dashboard authentication check works")
            tests_passed += 1
        else:
            print(f"✗ Dashboard authentication failed: {response.status_code}")
    except Exception as e:
        print(f"✗ Dashboard test failed: {e}")
    
    print("=" * 50)
    print(f"Tests passed: {tests_passed}/{total_tests}")
    
    if tests_passed == total_tests:
        print("🎉 All tests passed! Application is working correctly.")
        return True
    else:
        print("❌ Some tests failed. Please check the application.")
        return False

def check_application_running(base_url="http://localhost:5000"):
    """Check if the application is running"""
    try:
        response = requests.get(base_url, timeout=5)
        return True
    except:
        return False

if __name__ == "__main__":
    # Default URL
    url = "http://localhost:5000"
    
    # Check if URL is provided as argument
    if len(sys.argv) > 1:
        url = sys.argv[1]
    
    print("AWS Cloud Storage Application Test")
    print(f"Testing URL: {url}")
    print()
    
    # Check if application is running
    if not check_application_running(url):
        print("❌ Application is not running or not accessible.")
        print("Please start the application first:")
        print("  python app.py")
        print("  or")
        print("  ./start.sh")
        sys.exit(1)
    
    # Run tests
    success = test_application(url)
    
    if success:
        sys.exit(0)
    else:
        sys.exit(1)
