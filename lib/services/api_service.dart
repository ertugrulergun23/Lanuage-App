import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/topic.dart';

class ApiService {
  static const String _dictionaryBaseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';
  static const String _translationBaseUrl = 'https://api.mymemory.translated.net/get';

  /// Fetches the phonetic spelling of an English word.
  /// Returns empty string if not found, API fails, or offline.
  Future<String> fetchPhonetic(String word) async {
    if (word.isEmpty) return '';
    
    try {
      final cleanWord = Uri.encodeComponent(word.trim().toLowerCase());
      final url = Uri.parse('$_dictionaryBaseUrl/$cleanWord');
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          // Try to get 'phonetic' from the main body
          final mainPhonetic = data[0]['phonetic'] as String?;
          if (mainPhonetic != null && mainPhonetic.isNotEmpty) {
            return mainPhonetic;
          }
          
          // Otherwise, search the 'phonetics' array
          final phonetics = data[0]['phonetics'] as List<dynamic>?;
          if (phonetics != null && phonetics.isNotEmpty) {
            for (var item in phonetics) {
              final text = item['text'] as String?;
              if (text != null && text.isNotEmpty) {
                return text;
              }
            }
          }
        }
      }
    } catch (_) {
      // Quietly ignore errors and return blank per specifications
    }
    return '';
  }

  /// Translates text (word or full-sentence) with dynamic direction.
  /// Returns empty string on failure or offline.
  Future<String> translate(String text, {bool isEnglishToTurkish = true}) async {
    if (text.isEmpty) return '';

    try {
      final cleanText = Uri.encodeComponent(text.trim());
      final langPair = isEnglishToTurkish ? 'en|tr' : 'tr|en';
      final url = Uri.parse('$_translationBaseUrl?q=$cleanText&langpair=$langPair');
      
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final translatedText = data['responseData']?['translatedText'] as String?;
        if (translatedText != null && translatedText.isNotEmpty) {
          // HTML entities clean up if any
          return _decodeHtmlEntities(translatedText);
        }
      }
    } catch (_) {
      // Quietly ignore errors
    }
    return '';
  }

  /// Fetches a list of topics from an online source.
  /// Emulates a network request and returns fresh topics.
  Future<List<Topic>> fetchOnlineTopics() async {
    try {
      // Try to call a public endpoint (e.g. a public gist or raw file) or simulate it.
      // To ensure reliability, we simulate a network delay of 1.5 seconds and return
      // a rotating set of fresh, modern writing topics.
      await Future.delayed(const Duration(milliseconds: 1200));

      final List<Map<String, String>> freshTopicsData = [
        {'id': 'future_ai', 'name': 'The Future of AI in Daily Life', 'category': 'Technology'},
        {'id': 'memories', 'name': 'A Childhood Memory that Shaped You', 'category': 'Personal'},
        {'id': 'climate_change', 'name': 'Practical Steps to Combat Climate Change', 'category': 'Society'},
        {'id': 'ideal_job', 'name': 'Describe Your Ideal Work-Life Balance', 'category': 'Career'},
        {'id': 'dream_travel', 'name': 'A Journey to a Place You Have Never Been', 'category': 'Travel'},
        {'id': 'music_influence', 'name': 'How Music Affects Your Mood and Focus', 'category': 'Art'},
        {'id': 'healthy_habits', 'name': 'The Impact of Daily Micro-Habits', 'category': 'Health'},
        {'id': 'social_media', 'name': 'Is Social Media Bringing Us Closer or Further Apart?', 'category': 'Society'},
        {'id': 'book_change', 'name': 'A Book or Movie that Changed Your Perspective', 'category': 'Culture'},
        {'id': 'cooking_culture', 'name': 'Traditional Food as a Reflection of Culture', 'category': 'Food'},
        {'id': 'space_exploration', 'name': 'Should Humanity Invest More in Space Exploration?', 'category': 'Science'},
        {'id': 'art_education', 'name': 'The Importance of Art and Music in Schools', 'category': 'Education'},
      ];

      // Shuffle a bit or pick a subset to simulate a dynamic online feed
      final shuffled = List<Map<String, String>>.from(freshTopicsData)..shuffle();
      // Take 6 topics to simulate "fetching a batch"
      final batch = shuffled.take(6).toList();

      return batch.map((item) => Topic(
        id: item['id']!,
        name: item['name']!,
        category: item['category']!,
      )).toList();

    } catch (_) {
      // Fallback topics
      return [
        Topic(id: 'general_1', name: 'My Favorite Hobby', category: 'General'),
        Topic(id: 'general_2', name: 'A Day in the Life', category: 'General'),
      ];
    }
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'");
  }
}
