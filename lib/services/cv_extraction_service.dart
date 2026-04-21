/// CV Extraction Service - Pick PDF files and extract text
library;

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Result of CV extraction
class CVExtractionResult {
  final String fileName;
  final String filePath;
  final String extractedText;
  final CVParsedData? parsedData;

  const CVExtractionResult({
    required this.fileName,
    required this.filePath,
    required this.extractedText,
    this.parsedData,
  });

  @override
  String toString() =>
      'CVExtractionResult(fileName: $fileName, filePath: $filePath, '
      'extractedText: ${extractedText.length} chars, '
      'parsedData: ${parsedData != null ? "yes" : "no"})';
}

/// Parsed CV data
class CVParsedData {
  final String name;
  final List<String> skills;
  final String summary;
  final int? yearsOfExperience;
  final String? email;
  final String? phone;

  const CVParsedData({
    required this.name,
    this.skills = const [],
    required this.summary,
    this.yearsOfExperience,
    this.email,
    this.phone,
  });

  CVParsedData copyWith({
    String? name,
    List<String>? skills,
    String? summary,
    int? yearsOfExperience,
    String? email,
    String? phone,
  }) {
    return CVParsedData(
      name: name ?? this.name,
      skills: skills ?? this.skills,
      summary: summary ?? this.summary,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'skills': skills,
        'summary': summary,
        if (yearsOfExperience != null) 'years_of_experience': yearsOfExperience,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };

  factory CVParsedData.fromJson(Map<String, dynamic> json) {
    return CVParsedData(
      name: json['name'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      summary: json['summary'] as String? ?? '',
      yearsOfExperience: json['years_of_experience'] as int?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  @override
  String toString() =>
      'CVParsedData(name: $name, skills: ${skills.length}, '
      'yearsOfExperience: $yearsOfExperience)';
}

/// Service for picking and extracting text from CV PDF files
class CVExtractionService {
  /// Pick a PDF file and extract text
  Future<CVExtractionResult?> pickAndExtract() async {
    try {
      // Pick PDF file
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[CVExtraction] No file selected');
        return null;
      }

      final file = result.files.single;
      final fileName = file.name;
      final filePath = file.path;

      // Get file bytes
      Uint8List bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (filePath != null) {
        final fileData = File(filePath);
        bytes = await fileData.readAsBytes();
      } else {
        debugPrint('[CVExtraction] No file data available');
        return null;
      }

      // Extract text
      final extractedText = await extractTextFromPDF(bytes);

      // Parse CV data
      final parsedData = await parseCVText(extractedText);

      return CVExtractionResult(
        fileName: fileName,
        filePath: filePath ?? '',
        extractedText: extractedText,
        parsedData: parsedData,
      );
    } catch (e) {
      debugPrint('[CVExtraction] Error picking and extracting: $e');
      rethrow;
    }
  }

  /// Extract text from PDF bytes
  Future<String> extractTextFromPDF(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text;
    } catch (e) {
      debugPrint('[CVExtraction] Error extracting text: $e');
      rethrow;
    }
  }

  /// Parse CV text into structured data
  ///
  /// This is a simple heuristic parser. For production, consider using AI
  /// to parse the CV text more accurately.
  Future<CVParsedData> parseCVText(String text) async {
    final lines = text.split('\n').map((line) => line.trim()).toList();

    // Find name (usually first non-empty line or before "Email"/"Phone")
    var name = '';
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      // Skip common headers
      if (line.contains('CURRICULUM VITAE') ||
          line.contains('RESUME') ||
          line.contains('CV') ||
          line.toLowerCase().contains('curriculum')) {
        continue;
      }
      // Name is usually short and doesn't contain common words
      if (line.split(' ').length <= 4 &&
          !line.contains('@') &&
          !line.contains('http') &&
          !RegExp(r'^[\d\s\-\+]+$').hasMatch(line)) {
        name = line;
        break;
      }
    }

    // Find email
    String? email;
    final emailRegex = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+');
    for (final line in lines) {
      final match = emailRegex.firstMatch(line);
      if (match != null) {
        email = match.group(0);
        break;
      }
    }

    // Find phone
    String? phone;
    final phoneRegex = RegExp(r'(\+?\d{1,3}[-.\s]?)?\(?\d{3,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{4,6}');
    for (final line in lines) {
      final match = phoneRegex.firstMatch(line);
      if (match != null) {
        phone = match.group(0);
        break;
      }
    }

    // Find years of experience
    int? yearsOfExperience;
    final expRegex = RegExp(r'(\d+)\+?\s*(years?|tahun|thn)', caseSensitive: false);
    for (final line in lines) {
      final match = expRegex.firstMatch(line);
      if (match != null) {
        yearsOfExperience = int.tryParse(match.group(1) ?? '');
        break;
      }
    }

    // Find skills section
    final skills = <String>[];
    final skillKeywords = [
      'skills',
      'keahlian',
      'skill',
      'technologies',
      'tech stack',
      'tools',
      'competencies',
    ];

    var inSkillsSection = false;
    for (final line in lines) {
      final lowerLine = line.toLowerCase();

      // Check if we're entering skills section
      for (final keyword in skillKeywords) {
        if (lowerLine.contains(keyword)) {
          inSkillsSection = true;
          break;
        }
      }

      // Check if we're leaving skills section
      if (inSkillsSection && line.isEmpty) {
        // End of skills section
        break;
      }

      // Extract skills if in section
      if (inSkillsSection && line.isNotEmpty && !line.contains(':')) {
        // Parse skill line (could be comma separated, bulleted, etc.)
        final skillParts = line
            .replaceAll(RegExp(r'[\*\•\-\+]+'), '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.length > 1 && s.length < 50)
            .toList();
        skills.addAll(skillParts);
      }
    }

    // Build summary from first few meaningful lines
    final summaryLines = <String>[];
    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line.length > 30 && !line.contains('@') && !line.contains('http')) {
        summaryLines.add(line);
        if (summaryLines.length >= 3) break;
      }
    }
    final summary = summaryLines.join(' ').substring(
        0, summaryLines.join(' ').length > 500 ? 500 : summaryLines.join(' ').length);

    return CVParsedData(
      name: name.isEmpty ? 'Tanpa Nama' : name,
      skills: skills.toSet().toList(),
      summary: summary.isEmpty ? 'Tidak ada summary' : summary,
      yearsOfExperience: yearsOfExperience,
      email: email,
      phone: phone,
    );
  }
}
