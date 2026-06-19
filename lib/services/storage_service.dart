import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';

class StorageService {
  static const String _keyWords = 'lingoglow_cached_words';
  static const String _keySupabaseUrl = 'lingoglow_supabase_url';
  static const String _keySupabaseKey = 'lingoglow_supabase_key';
  
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Initialize service
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    service._prepopulateIfEmpty();
    return service;
  }

  // --- Supabase Config Storage ---
  String? get supabaseUrl => _prefs.getString(_keySupabaseUrl);
  String? get supabaseKey => _prefs.getString(_keySupabaseKey);

  Future<void> saveSupabaseConfig(String url, String key) async {
    await _prefs.setString(_keySupabaseUrl, url);
    await _prefs.setString(_keySupabaseKey, key);
  }

  Future<void> clearSupabaseConfig() async {
    await _prefs.remove(_keySupabaseUrl);
    await _prefs.remove(_keySupabaseKey);
  }

  // --- Local Vocabulary Cache ---
  List<WordModel> getWords() {
    final jsonStr = _prefs.getString(_keyWords);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => WordModel.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveWords(List<WordModel> words) async {
    final list = words.map((w) => w.toJson()).toList();
    await _prefs.setString(_keyWords, jsonEncode(list));
  }

  // Prepopulate dictionary if empty for testing
  void _prepopulateIfEmpty() {
    if (_prefs.getString(_keyWords) == null) {
      final defaultWords = [
        WordModel(
          id: 'prepop-1',
          word: 'accommodate',
          definition: '容納；提供住宿；適應',
          synonyms: ['house', 'hold', 'adapt', 'fit', 'lodge'],
          antonyms: ['exclude', 'reject', 'displace'],
          sampleSentence: 'The luxury resort can accommodate up to 500 guests.',
          repetitions: 0,
          interval: 0,
          easeFactor: 2.5,
          nextReviewDate: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        WordModel(
          id: 'prepop-2',
          word: 'benevolent',
          definition: '仁慈的；善意的；樂善好施的',
          synonyms: ['kind', 'generous', 'charitable', 'benign', 'caring'],
          antonyms: ['malevolent', 'cruel', 'spiteful'],
          sampleSentence: 'A benevolent donor provided funding for the new library.',
          repetitions: 0,
          interval: 0,
          easeFactor: 2.5,
          nextReviewDate: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        WordModel(
          id: 'prepop-3',
          word: 'ephemeral',
          definition: '轉瞬即逝的；短暫的',
          synonyms: ['transitory', 'fleeting', 'short-lived', 'momentary'],
          antonyms: ['permanent', 'eternal', 'lasting', 'perpetual'],
          sampleSentence: 'Fame in the internet age is often ephemeral, fading in weeks.',
          repetitions: 0,
          interval: 0,
          easeFactor: 2.5,
          nextReviewDate: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
      saveWords(defaultWords);
    }
  }
}
