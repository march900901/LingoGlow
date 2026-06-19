import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word_model.dart';
import 'storage_service.dart';

class SupabaseService with ChangeNotifier {
  final StorageService _storage;
  SupabaseClient? _client;
  bool _isConnecting = false;
  bool _isConnected = false;
  
  SupabaseService(this._storage) {
    _initClientFromStorage();
  }

  SupabaseClient? get client => _client;
  String? get supabaseUrl => _storage.supabaseUrl;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get hasCredentials => _storage.supabaseUrl != null && _storage.supabaseKey != null;
  
  User? get currentUser => _client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  void _initClientFromStorage() {
    final url = _storage.supabaseUrl;
    final key = _storage.supabaseKey;
    if (url != null && key != null && url.isNotEmpty && key.isNotEmpty) {
      try {
        _client = SupabaseClient(url, key);
        _isConnected = true;
      } catch (e) {
        debugPrint('Failed to initialize Supabase client: $e');
        _isConnected = false;
      }
    }
  }

  /// Dynamically setup/change Supabase credentials
  Future<bool> connect(String url, String key) async {
    _isConnecting = true;
    notifyListeners();
    
    try {
      final tempClient = SupabaseClient(url, key);
      // Attempt a simple query to verify the connection works
      await tempClient.from('words').select().limit(1).maybeSingle();
      
      _client = tempClient;
      await _storage.saveSupabaseConfig(url, key);
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Supabase connection verification failed: $e');
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    await _storage.clearSupabaseConfig();
    _client = null;
    _isConnected = false;
    notifyListeners();
  }

  // --- Auth Actions ---
  
  /// Initiates Google Login via standard Supabase Auth
  Future<bool> signInWithGoogle() async {
    if (_client == null) return false;
    try {
      // In Flutter Web/Mobile, we trigger OAuth sign-in.
      // Supabase supports google OAuth provider.
      await _client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.lingoglow://login-callback',
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    if (_client == null) return;
    await _client!.auth.signOut();
    notifyListeners();
  }

  // --- Database Sync Actions ---

  /// Pushes local words to Supabase and pulls remote words, merging them.
  Future<List<WordModel>> syncWords(List<WordModel> localWords) async {
    if (_client == null || !isAuthenticated) return localWords;
    final user = currentUser!;
    
    try {
      // 1. Fetch remote words
      final List<dynamic> remoteData = await _client!
          .from('words')
          .select()
          .eq('user_id', user.id);
          
      final remoteWords = remoteData.map((json) => WordModel.fromJson(json)).toList();
      
      // 2. Perform merge (latest updated_at wins)
      final Map<String, WordModel> mergedMap = {};
      
      // Add remote words to map
      for (final rw in remoteWords) {
        if (rw.id != null) {
          mergedMap[rw.word.toLowerCase()] = rw;
        }
      }

      // Merge local words
      final List<WordModel> toUpload = [];
      for (final lw in localWords) {
        final key = lw.word.toLowerCase();
        final match = mergedMap[key];
        
        if (match == null) {
          // New local word, associate with user and queue for upload
          final freshWord = lw.copyWith(userId: user.id);
          mergedMap[key] = freshWord;
          toUpload.add(freshWord);
        } else {
          // Word exists in both. Compare timestamps.
          final localTime = lw.updatedAt ?? lw.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final remoteTime = match.updatedAt ?? match.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          
          if (localTime.isAfter(remoteTime)) {
            // Local is newer, update map and queue upload
            final updatedWord = lw.copyWith(id: match.id, userId: user.id);
            mergedMap[key] = updatedWord;
            toUpload.add(updatedWord);
          }
        }
      }

      // 3. Upload changes to Supabase (Upsert)
      if (toUpload.isNotEmpty) {
        final uploadJson = toUpload.map((w) {
          final json = w.toJson();
          // Remove client-only placeholder IDs like 'prepop-X'
          if (w.id != null && w.id!.startsWith('prepop-')) {
            json.remove('id');
          }
          return json;
        }).toList();
        
        await _client!.from('words').upsert(uploadJson);
      }

      // 4. Fetch final updated list from Supabase to ensure clean state
      final List<dynamic> finalRemoteData = await _client!
          .from('words')
          .select()
          .eq('user_id', user.id);
          
      final finalWords = finalRemoteData.map((json) => WordModel.fromJson(json)).toList();
      
      // Save merged list locally
      await _storage.saveWords(finalWords);
      notifyListeners();
      return finalWords;
      
    } catch (e) {
      debugPrint('Sync error: $e');
      return localWords; // Return unchanged local if error
    }
  }

  /// Adds a word to database
  Future<WordModel?> addWord(WordModel word) async {
    if (_client == null || !isAuthenticated) return null;
    try {
      final json = word.toJson();
      if (word.id != null && word.id!.startsWith('prepop-')) {
        json.remove('id');
      }
      json['user_id'] = currentUser!.id;

      final res = await _client!.from('words').insert(json).select().single();
      return WordModel.fromJson(res);
    } catch (e) {
      debugPrint('Add word error: $e');
      return null;
    }
  }

  /// Updates a word in database
  Future<bool> updateWord(WordModel word) async {
    if (_client == null || !isAuthenticated || word.id == null) return false;
    try {
      final json = word.toJson();
      json['user_id'] = currentUser!.id;
      
      await _client!.from('words').update(json).eq('id', word.id!);
      return true;
    } catch (e) {
      debugPrint('Update word error: $e');
      return false;
    }
  }

  /// Deletes a word in database
  Future<bool> deleteWord(String id) async {
    if (_client == null || !isAuthenticated) return false;
    // Skip deleting local prepopulated IDs on cloud
    if (id.startsWith('prepop-')) return true;
    try {
      await _client!.from('words').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Delete word error: $e');
      return false;
    }
  }
}
