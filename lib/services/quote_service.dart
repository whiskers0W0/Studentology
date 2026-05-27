import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class QuoteService {
  static const _fallbacks = [
    {'quote': 'The secret of getting ahead is getting started.', 'author': 'Mark Twain'},
    {'quote': 'Education is the most powerful weapon which you can use to change the world.', 'author': 'Nelson Mandela'},
    {'quote': 'An investment in knowledge pays the best interest.', 'author': 'Benjamin Franklin'},
    {'quote': 'The beautiful thing about learning is that nobody can take it away from you.', 'author': 'B.B. King'},
    {'quote': 'It always seems impossible until it\'s done.', 'author': 'Nelson Mandela'},
    {'quote': 'Believe you can and you\'re halfway there.', 'author': 'Theodore Roosevelt'},
    {'quote': 'The only way to do great work is to love what you do.', 'author': 'Steve Jobs'},
    {'quote': 'In the middle of every difficulty lies opportunity.', 'author': 'Albert Einstein'},
    {'quote': 'The expert in anything was once a beginner.', 'author': 'Helen Hayes'},
    {'quote': 'The more that you read, the more things you will know.', 'author': 'Dr. Seuss'},
    {'quote': 'Don\'t watch the clock; do what it does. Keep going.', 'author': 'Sam Levenson'},
    {'quote': 'You don\'t have to be great to start, but you have to start to be great.', 'author': 'Zig Ziglar'},
    {'quote': 'A year from now you may wish you had started today.', 'author': 'Karen Lamb'},
    {'quote': 'Push yourself, because no one else is going to do it for you.', 'author': 'Anonymous'},
    {'quote': 'Dream big and dare to fail.', 'author': 'Norman Vaughan'},
    {'quote': 'What you get by achieving your goals is not as important as what you become by achieving your goals.', 'author': 'Zig Ziglar'},
    {'quote': 'Learning is not attained by chance; it must be sought with ardor and attended to with diligence.', 'author': 'Abigail Adams'},
    {'quote': 'The future belongs to those who believe in the beauty of their dreams.', 'author': 'Eleanor Roosevelt'},
    {'quote': 'Strive not to be a success, but rather to be of value.', 'author': 'Albert Einstein'},
    {'quote': 'The only limit to our realization of tomorrow is our doubts of today.', 'author': 'Franklin D. Roosevelt'},
    {'quote': 'Success is no accident. It is hard work, perseverance, learning, studying, and love of what you are doing.', 'author': 'Pelé'},
    {'quote': 'Great things never come from comfort zones.', 'author': 'Anonymous'},
    {'quote': 'The harder you work for something, the greater you\'ll feel when you achieve it.', 'author': 'Anonymous'},
  ];

  static Map<String, String> _randomFallback() {
    final q = _fallbacks[Random().nextInt(_fallbacks.length)];
    return {'quote': q['quote']!, 'author': q['author']!};
  }

  static Future<Map<String, String>> fetchRandomQuote() async {
    if (kIsWeb) {
      return _randomFallback();
    }

    try {
      final response = await http
          .get(Uri.parse('https://zenquotes.io/api/random'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final item = data[0] as Map<String, dynamic>;
          return {
            'quote': item['q'] as String? ?? '',
            'author': item['a'] as String? ?? 'Unknown',
          };
        }
      }
    } catch (_) {}

    return _randomFallback();
  }
}
