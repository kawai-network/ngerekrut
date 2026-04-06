/// Function calling tools for JobPosting generation.
library;

import 'dart:convert';

/// Tool schema for generating JobPosting via function calling.
class JobPostingTool {
  /// Get the tool schema for function calling.
  static Map<String, dynamic> get schema => {
        'name': 'generate_job_posting',
        'description': 'Generate a complete job posting with all required fields',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'Job title (e.g., "Kasir", "Software Engineer")',
            },
            'location': {
              'type': 'string',
              'description': 'Job location (e.g., "Jakarta", "Remote")',
            },
            'employment_type': {
              'type': 'string',
              'description': 'Employment type (e.g., "Full-time", "Part-time", "Contract")',
              'enum': ['Full-time', 'Part-time', 'Contract', 'Internship'],
            },
            'description': {
              'type': 'string',
              'description': 'Detailed job description explaining the role and company',
            },
            'requirements': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of qualifications and requirements',
            },
            'responsibilities': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of key responsibilities',
            },
            'salary_range': {
              'type': 'string',
              'description': 'Salary range (e.g., "5-8 Juta", "IDR 10.000.000 - 15.000.000")',
            },
          },
          'required': [
            'title',
            'location',
            'employment_type',
            'description',
            'requirements',
            'responsibilities',
            'salary_range',
          ],
        },
      };

  /// Parse function call result from AI response.
  ///
  /// Extracts JSON from various formats the AI might return.
  static Map<String, dynamic>? parseFunctionCall(String response) {
    // Try to parse as direct JSON first
    try {
      final json = _extractJson(response);
      if (json != null) {
        // Check if it has function field
        if (json.containsKey('function')) {
          final functionName = json['function'] as String?;
          if (functionName == 'generate_job_posting') {
            return json['arguments'] as Map<String, dynamic>?;
          }
        }
        // If no function field, check if it's the arguments directly
        if (_isValidJobPosting(json)) {
          return json;
        }
      }
    } catch (e) {
      // Continue to other parsing methods
    }

    return null;
  }

  /// Extract JSON from AI response.
  static Map<String, dynamic>? _extractJson(String response) {
    // Remove markdown code blocks
    var cleaned = response.trim();

    // Remove ```json ... ``` or ``` ... ```
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final codeMatch = codeBlockRegex.firstMatch(cleaned);
    if (codeMatch != null) {
      cleaned = codeMatch.group(1)!;
    }

    // Find JSON object
    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');

    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      return null;
    }

    final jsonString = cleaned.substring(jsonStart, jsonEnd + 1);

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Validate if the JSON has required JobPosting fields.
  static bool _isValidJobPosting(Map<String, dynamic> json) {
    return json.containsKey('title') &&
        json.containsKey('location') &&
        json.containsKey('employment_type');
  }
}
