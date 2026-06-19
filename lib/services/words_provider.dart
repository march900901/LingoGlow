import 'package:flutter/material.dart';
import '../models/word_model.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class WordsProvider with ChangeNotifier {
  final StorageService _storage;
  final SupabaseService _supabase;
  
  List<WordModel> _words = [];
  bool _isLoading = false;

  // Active Review Session State
  List<WordModel> _reviewQueue = [];
  int _currentQueueIndex = 0;
  bool _isSessionActive = false;
  
  WordsProvider(this._storage, this._supabase) {
    _loadWords();
    // Listen to Supabase auth state changes to trigger sync
    _supabase.addListener(_onSupabaseStateChanged);
  }

  List<WordModel> get words => _words;
  bool get isLoading => _isLoading;

  // Review getters
  bool get isSessionActive => _isSessionActive;
  List<WordModel> get reviewQueue => _reviewQueue;
  int get currentQueueIndex => _currentQueueIndex;
  WordModel? get currentReviewWord => 
      (_isSessionActive && _reviewQueue.isNotEmpty && _currentQueueIndex < _reviewQueue.length)
          ? _reviewQueue[_currentQueueIndex]
          : null;
          
  int get dueCount => _words.where((w) => w.isDue).length;
  int get totalCount => _words.length;
  int get masteredCount => _words.where((w) => w.repetitions >= 4).length;

  void _loadWords() {
    _words = _storage.getWords();
    notifyListeners();
  }

  void _onSupabaseStateChanged() {
    // If user just logged in, trigger sync
    if (_supabase.isAuthenticated) {
      syncWithCloud();
    }
  }

  /// Cloud synchronization
  Future<void> syncWithCloud() async {
    if (!_supabase.isConnected || !_supabase.isAuthenticated) return;
    _isLoading = true;
    notifyListeners();

    try {
      final mergedWords = await _supabase.syncWords(_words);
      _words = mergedWords;
    } catch (e) {
      debugPrint('Sync error in provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CRUD Operations ---

  Future<void> addWord({
    required String word,
    required String definition,
    required List<String> synonyms,
    required List<String> antonyms,
    String? sampleSentence,
  }) async {
    final newWord = WordModel(
      word: word.trim(),
      definition: definition.trim(),
      synonyms: synonyms.map((s) => s.trim().toLowerCase()).toList(),
      antonyms: antonyms.map((a) => a.trim().toLowerCase()).toList(),
      sampleSentence: sampleSentence?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save locally first
    _words.add(newWord);
    await _storage.saveWords(_words);
    notifyListeners();

    // Push to Supabase if logged in
    if (_supabase.isAuthenticated) {
      final remoteWord = await _supabase.addWord(newWord);
      if (remoteWord != null) {
        // Replace temporary local word with remote word containing actual database ID
        final idx = _words.indexWhere((w) => w.word.toLowerCase() == word.toLowerCase());
        if (idx != -1) {
          _words[idx] = remoteWord;
          await _storage.saveWords(_words);
          notifyListeners();
        }
      }
    }
  }

  Future<void> updateWord(WordModel updated) async {
    final idx = _words.indexWhere((w) => w.word.toLowerCase() == updated.word.toLowerCase() || (w.id != null && w.id == updated.id));
    if (idx == -1) return;

    _words[idx] = updated.copyWith(updatedAt: DateTime.now());
    await _storage.saveWords(_words);
    notifyListeners();

    if (_supabase.isAuthenticated) {
      await _supabase.updateWord(_words[idx]);
    }
  }

  Future<void> deleteWord(String id) async {
    _words.removeWhere((w) => w.id == id);
    await _storage.saveWords(_words);
    notifyListeners();

    if (_supabase.isAuthenticated) {
      await _supabase.deleteWord(id);
    }
  }

  // --- Review Session Management ---

  void startReviewSession() {
    // Collect all due words and shuffle for random practice
    _reviewQueue = _words.where((w) => w.isDue).toList()..shuffle();
    _currentQueueIndex = 0;
    _isSessionActive = _reviewQueue.isNotEmpty;
    notifyListeners();
  }

  void endReviewSession() {
    _isSessionActive = false;
    _reviewQueue = [];
    _currentQueueIndex = 0;
    notifyListeners();
  }

  /// Rates the current review word using SM-2 quality [1-5]
  Future<void> rateCurrentWord(int quality) async {
    if (currentReviewWord == null) return;
    
    final updated = currentReviewWord!.updateSRS(quality);
    
    // Update locally and in list
    await updateWord(updated);
    
    // Move to next word
    _currentQueueIndex++;
    if (_currentQueueIndex >= _reviewQueue.length) {
      _isSessionActive = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _supabase.removeListener(_onSupabaseStateChanged);
    super.dispose();
  }
}
