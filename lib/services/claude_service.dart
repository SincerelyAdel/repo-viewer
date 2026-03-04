import 'dart:convert';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-6';
  final String apiKey;

  ClaudeService({required this.apiKey});

  /// Generate a lab report from a map of filename -> content
  Stream<String> generateReport(
    Map<String, String> files,
    String repoName, {
    String? labNumber,
    String? extraInstructions,
  }) async* {
    final filesDump = files.entries
        .map((e) => '=== ${e.key} ===\n${e.value}')
        .join('\n\n');

    final prompt = '''
You are a professional IC design lab report writer at EQSemi, Riyadh, KSA.

Generate a detailed lab report for the following Verilog HDL files from the repository "$repoName"${labNumber != null ? ', Lab $labNumber' : ''}.

The report must include for each module:
1. Overview and purpose
2. Block diagram description (described textually as ASCII art or structured description)
3. Full source code snippet
4. Design notes and analysis
5. Truth table where applicable

Format the report in Markdown with clear headings.
${extraInstructions != null ? '\nAdditional instructions: $extraInstructions' : ''}

--- FILES ---
$filesDump
''';

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 4096,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['content'][0]['text'] as String;
      yield text;
    } else {
      throw Exception(
          'Claude API error ${response.statusCode}: ${response.body}');
    }
  }

  /// Explain a single file
  Future<String> explainFile(String filename, String content) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content':
                'Explain this Verilog file concisely as an IC design engineer would. Focus on what it does, its ports, and any key design decisions.\n\nFile: $filename\n\n$content'
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    }
    throw Exception('Claude API error: ${response.statusCode}');
  }
}
