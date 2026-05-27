import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class StudentologyAIService {
  static const String _apiKey = ApiKeys.openRouter;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Generates 5 thesis/capstone topic ideas for a Filipino college student.
  ///
  /// Returns a [List<String>] where each entry is one complete idea block
  /// (numbered heading + 2-sentence description) parsed from the model response.
  ///
  /// Throws an [Exception] on HTTP errors or when the response cannot be parsed.
  Future<List<String>> generateThesisIdeas(
    String course,
    String interests,
  ) async {
    final prompt = _buildPrompt(course, interests);
    final responseText = await _callApi(prompt);
    return _parseIdeas(responseText);
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  String _buildPrompt(String course, String interests) {
    return 'Generate 5 unique and creative capstone or thesis topic ideas for a '
        'Filipino college student taking $course. '
        'Their interests and topics include: $interests. '
        'For each idea, provide: (1) a clear descriptive title, and (2) a 2-sentence '
        'description explaining the concept and its relevance to Filipino society or '
        'the local context. Format as a numbered list with each idea clearly separated.';
  }

  Future<String> _callApi(String prompt) async {
    final models = [
      'openrouter/auto',
      'meta-llama/llama-3.3-70b-instruct:free',
      'meta-llama/llama-4-scout:free',
    ];

    Exception? lastError;

    for (final model in models) {
      try {
        debugPrint('Trying model: $model');
        final response = await http.post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            'HTTP-Referer': 'https://studentology.app',
            'X-Title': 'Studentology',
          },
          body: jsonEncode({
            "model": model,
            "messages": [
              {
                "role": "system",
                "content":
                    "You are an academic advisor helping Filipino college students brainstorm thesis and capstone project ideas. Always respond with exactly 5 numbered ideas, each with a title and 2-sentence description."
              },
              {
                "role": "user",
                "content": prompt,
              }
            ],
            "max_tokens": 1500,
            "temperature": 0.8,
          }),
        ).timeout(const Duration(seconds: 45));

        debugPrint('Model $model status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices']?[0]?['message']?['content'];
          if (content != null && content.toString().isNotEmpty) {
            return content.toString();
          }
        }

        if (response.statusCode == 429) {
          throw Exception(
              'Rate limit reached. Please wait a moment and try again.');
        }

        lastError = Exception(
            'Model $model failed with status ${response.statusCode}');
      } catch (e) {
        debugPrint('Model $model error: $e');
        lastError = e is Exception ? e : Exception(e.toString());
        if (e.toString().contains('Rate limit')) rethrow;
        continue;
      }
    }

    throw lastError ??
        Exception(
            'All models failed. Please check your internet connection and try again.');
  }

  /// Splits the numbered-list response into individual idea strings.
  ///
  /// Each idea in the model response looks like:
  ///   1. Title Here
  ///   Description sentence one. Description sentence two.
  ///
  /// The method accumulates lines between numbered headers and returns each
  /// block as a single trimmed string.
  List<String> _parseIdeas(String text) {
    final lines = text.split('\n');
    final ideas = <String>[];
    final buffer = StringBuffer();
    bool inIdea = false;

    // A line starting with a digit followed by '.' is a new numbered item.
    final numberedEntry = RegExp(r'^\d+\.');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (numberedEntry.hasMatch(trimmed)) {
        // Flush the previous idea before starting a new one.
        if (inIdea) {
          final previous = buffer.toString().trim();
          if (previous.isNotEmpty) ideas.add(previous);
        }
        buffer.clear();
        buffer.write(trimmed);
        inIdea = true;
      } else if (inIdea) {
        // Continuation line — append with a space to join title + description.
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(trimmed);
      }
      // Lines before the first numbered entry (intro text) are discarded.
    }

    // Flush the final idea.
    if (inIdea) {
      final last = buffer.toString().trim();
      if (last.isNotEmpty) ideas.add(last);
    }

    // Guard against malformed responses by returning whatever was parsed.
    return ideas.where((s) => s.isNotEmpty).toList();
  }
}
