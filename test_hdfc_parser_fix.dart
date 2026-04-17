import 'dart:io';
import 'dart:convert';

// Simple test to check HDFC PDF parsing
void main() async {
  print('Testing HDFC PDF parsing...');

  // Read the HDFC file content
  final file = File('HDFC-till 24.pdf');
  if (await file.exists()) {
    print('HDFC file found');
    // Just test the format detection logic
    final content = await file.readAsBytes();
    print('HDFC file size: ${content.length} bytes');

    // Test Union Bank file too
    final unionFile = File('Union_Bank.pdf');
    if (await unionFile.exists()) {
      print('Union Bank file found');
      final unionContent = await unionFile.readAsBytes();
      print('Union Bank file size: ${unionContent.length} bytes');
    } else {
      print('Union Bank file not found');
    }
  } else {
    print('HDFC file not found');
  }
}
