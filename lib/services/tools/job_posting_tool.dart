/// Function calling tools for JobPosting generation.
library;

import '../../langchain_gemma/langchain_gemma.dart';

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
    return LocalToolCallParser.parseArguments(
      response,
      expectedFunction: 'generate_job_posting',
      directValidator: _isValidJobPosting,
    );
  }

  /// Validate if the JSON has required JobPosting fields.
  static bool _isValidJobPosting(Map<String, dynamic> json) {
    return json.containsKey('title') &&
        json.containsKey('location') &&
        json.containsKey('employment_type');
  }
}
