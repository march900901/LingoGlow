class Dictionary {
  /// A compact set of ~1000 common English words to use as a baseline spellchecker.
  static final Set<String> commonWords = {
    'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i', 'it', 'for',
    'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at', 'this', 'but', 'his', 'by',
    'from', 'they', 'we', 'say', 'her', 'she', 'or', 'an', 'will', 'my', 'one',
    'all', 'would', 'there', 'their', 'what', 'so', 'up', 'out', 'if', 'about',
    'who', 'get', 'which', 'go', 'me', 'when', 'make', 'can', 'like', 'time',
    'no', 'just', 'him', 'know', 'take', 'people', 'into', 'year', 'your', 'good',
    'some', 'could', 'them', 'see', 'other', 'than', 'then', 'now', 'look', 'only',
    'come', 'its', 'over', 'think', 'also', 'back', 'after', 'use', 'two', 'how',
    'our', 'work', 'first', 'well', 'way', 'even', 'new', 'want', 'because', 'any',
    'these', 'give', 'day', 'most', 'us', 'hotel', 'resort', 'guests', 'library',
    'funding', 'donor', 'fame', 'internet', 'weeks', 'fading', 'books', 'learn',
    'study', 'happy', 'sad', 'beautiful', 'excellent', 'amazing', 'kind', 'generous',
    'temporary', 'permanent', 'accommodate', 'benevolent', 'ephemeral', 'write',
    'sentence', 'make', 'do', 'read', 'speak', 'listen', 'learn', 'teach', 'teacher',
    'student', 'school', 'university', 'college', 'education', 'knowledge', 'wise',
    'clever', 'smart', 'intelligent', 'stupid', 'foolish', 'idiot', 'genius',
    // We can populate more or let any word that is in the user's synonyms/antonyms
    // list or is the target word be automatically accepted.
    // Let's add basic words to prevent false positives for common grammar:
    'am', 'is', 'are', 'was', 'were', 'been', 'being', 'has', 'had', 'having',
    'does', 'did', 'doing', 'will', 'would', 'shall', 'should', 'can', 'could',
    'may', 'might', 'must', 'ought', 'dare', 'need', 'used', 'using', 'used',
    'about', 'above', 'across', 'after', 'against', 'along', 'among', 'around',
    'at', 'before', 'behind', 'below', 'beneath', 'beside', 'between', 'beyond',
    'but', 'by', 'despite', 'down', 'during', 'except', 'for', 'from', 'in',
    'inside', 'into', 'like', 'near', 'of', 'off', 'on', 'onto', 'out', 'outside',
    'over', 'past', 'since', 'through', 'throughout', 'till', 'to', 'toward',
    'under', 'underneath', 'until', 'up', 'upon', 'with', 'within', 'without',
    'i', 'me', 'my', 'myself', 'we', 'us', 'our', 'ours', 'ourselves', 'you',
    'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his', 'himself',
    'she', 'her', 'hers', 'herself', 'it', 'its', 'itself', 'they', 'them',
    'their', 'theirs', 'themselves', 'what', 'which', 'who', 'whom', 'this',
    'that', 'these', 'those', 'am', 'is', 'are', 'was', 'were', 'be', 'been',
    'being', 'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing', 'a',
    'an', 'the', 'and', 'but', 'or', 'yet', 'so', 'if', 'because', 'as', 'until',
    'while', 'of', 'at', 'by', 'for', 'with', 'about', 'against', 'between',
    'into', 'through', 'during', 'before', 'after', 'above', 'below', 'to',
    'from', 'up', 'down', 'in', 'out', 'on', 'off', 'over', 'under', 'again',
    'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why', 'how',
    'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such',
    'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 's',
    't', 'can', 'will', 'just', 'don', 'should', 'now'
  };

  /// Clean formatting (lowercase and remove punctuation)
  static String cleanWord(String word) {
    return word.toLowerCase().replaceAll(RegExp(r"[^\w']"), '');
  }

  /// Evaluates if a given word is likely spelled correctly.
  /// Validates against common words, vocabulary entries, target words, or custom additions.
  static bool checkSpelling(String word, {List<String>? additionalAcceptedWords}) {
    final cleaned = cleanWord(word);
    if (cleaned.isEmpty) return true;
    if (RegExp(r'^\d+$').hasMatch(cleaned)) return true; // Accept pure numbers
    
    if (commonWords.contains(cleaned)) return true;
    if (additionalAcceptedWords != null && 
        additionalAcceptedWords.map((w) => w.toLowerCase()).contains(cleaned)) {
      return true;
    }
    return false;
  }
}
