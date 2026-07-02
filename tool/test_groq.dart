import 'dart:convert';
import 'dart:io';

import 'package:studyflow_ai/services/groq_service.dart';

Future<void> main() async {
  final file = File('secrets.json');
  if (!file.existsSync()) {
    stderr.writeln('Missing secrets.json — copy secrets.json.example');
    exit(1);
  }

  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final apiKey = data['GROQ_KEY'] as String? ?? '';
  if (apiKey.isEmpty || apiKey == 'your_groq_api_key_here') {
    stderr.writeln('Set GROQ_KEY in secrets.json');
    exit(1);
  }

  final service = GroqService(apiKey: apiKey);
  final text = await service.chat('Trả lời đúng 1 từ: OK');
  stdout.writeln('Groq OK: $text');
}
