import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryLookupResult {
  final String word;
  final String definition;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? sampleSentence;

  DictionaryLookupResult({
    required this.word,
    required this.definition,
    required this.synonyms,
    required this.antonyms,
    this.sampleSentence,
  });
}

class DictionaryLookupService {
  /// Fetches English word definitions, synonyms, antonyms, and Chinese translation.
  static Future<DictionaryLookupResult> lookup(String word) async {
    final cleanWord = word.trim().toLowerCase();
    if (cleanWord.isEmpty) {
      throw Exception('單字為空');
    }

    String definition = '';
    List<String> synonyms = [];
    List<String> antonyms = [];
    String? sampleSentence;

    // 1. Fetch Chinese translation from MyMemory API
    try {
      final translateUrl = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(cleanWord)}&langpair=en|zh-TW'
      );
      final response = await http.get(translateUrl).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = data['responseData']?['translatedText'] as String?;
        if (translated != null && translated.isNotEmpty) {
          // Clean up MyMemory sometimes wrapping text in quotes or returning error messages
          if (!translated.contains('MYMEMORY WARNING')) {
            definition = translated.trim();
          }
        }
      }
    } catch (e) {
      // Ignore translation failure, we will try to proceed with dictionary API
    }

    // 2. Fetch definitions, synonyms, antonyms, examples from Free Dictionary API
    try {
      final dictUrl = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$cleanWord');
      final response = await http.get(dictUrl).timeout(const Duration(seconds: 6));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final firstEntry = data[0] as Map<String, dynamic>;
          
          // Parse synonyms/antonyms at root level
          if (firstEntry['synonyms'] != null) {
            synonyms.addAll(List<String>.from(firstEntry['synonyms']));
          }
          if (firstEntry['antonyms'] != null) {
            antonyms.addAll(List<String>.from(firstEntry['antonyms']));
          }

          final meanings = firstEntry['meanings'] as List<dynamic>? ?? [];
          for (final meaning in meanings) {
            final meaningMap = meaning as Map<String, dynamic>;
            
            // Extract synonyms & antonyms from meaning levels
            if (meaningMap['synonyms'] != null) {
              synonyms.addAll(List<String>.from(meaningMap['synonyms']));
            }
            if (meaningMap['antonyms'] != null) {
              antonyms.addAll(List<String>.from(meaningMap['antonyms']));
            }

            // Extract definitions and search for a sample sentence
            final definitions = meaningMap['definitions'] as List<dynamic>? ?? [];
            for (final def in definitions) {
              final defMap = def as Map<String, dynamic>;
              if (sampleSentence == null && defMap['example'] != null) {
                sampleSentence = defMap['example'] as String;
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignore dictionary lookup failures
    }

    // Remove duplicates and clean up synonyms/antonyms
    synonyms = synonyms
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty && s != cleanWord)
        .toSet()
        .toList();
    antonyms = antonyms
        .map((a) => a.trim().toLowerCase())
        .where((a) => a.isNotEmpty && a != cleanWord)
        .toSet()
        .toList();

    // If translation failed but we need a definition, we can use a fallback
    if (definition.isEmpty) {
      definition = '未找到中文翻譯 (請手動輸入)';
    }

    return DictionaryLookupResult(
      word: word,
      definition: definition,
      synonyms: synonyms,
      antonyms: antonyms,
      sampleSentence: sampleSentence,
    );
  }
}
