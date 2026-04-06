import 'package:flutter_test/flutter_test.dart';
import 'package:ngerekrut/langchain_gemma/langchain_gemma.dart';

void main() {
  group('LocalToolCallParser', () {
    test('extracts JSON from markdown code blocks', () {
      const response = '''
Here is the result:
```json
{"foo":"bar","count":1}
```
''';

      final json = LocalToolCallParser.extractJson(response);

      expect(json, isNotNull);
      expect(json!['foo'], 'bar');
      expect(json['count'], 1);
    });

    test('parses typed data from raw JSON', () {
      const response = '{"name":"candidate","score":5}';

      final result = LocalToolCallParser.parse<Map<String, dynamic>>(
        response,
        (json) => json,
      );

      expect(result, isNotNull);
      expect(result!['name'], 'candidate');
      expect(result['score'], 5);
    });

    test('extracts function arguments for expected tool name', () {
      const response =
          '{"function":"generate_job_posting","arguments":{"title":"Kasir","location":"Jakarta","employment_type":"Full-time"}}';

      final result = LocalToolCallParser.parseArguments(
        response,
        expectedFunction: 'generate_job_posting',
      );

      expect(result, isNotNull);
      expect(result!['title'], 'Kasir');
      expect(result['location'], 'Jakarta');
    });

    test('falls back to direct JSON when validator passes', () {
      const response =
          '{"title":"Kasir","location":"Jakarta","employment_type":"Full-time"}';

      final result = LocalToolCallParser.parseArguments(
        response,
        expectedFunction: 'generate_job_posting',
        directValidator: (json) =>
            json.containsKey('title') && json.containsKey('employment_type'),
      );

      expect(result, isNotNull);
      expect(result!['title'], 'Kasir');
    });
  });
}
