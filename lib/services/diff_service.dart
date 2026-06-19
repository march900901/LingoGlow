enum DiffType { match, missing, extra }

class DiffSegment {
  final DiffType type;
  final String text;

  DiffSegment(this.type, this.text);

  @override
  String toString() => 'DiffSegment($type, "$text")';
}

class DiffService {
  /// Compares [user] input against [correct] spelling and returns a list of
  /// [DiffSegment] indicating character-level differences.
  static List<DiffSegment> diffStrings(String user, String correct) {
    final m = user.length;
    final n = correct.length;
    
    // DP Table for Longest Common Subsequence
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (user[i - 1].toLowerCase() == correct[j - 1].toLowerCase()) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }

    int i = m;
    int j = n;
    final List<DiffSegment> result = [];

    // Backtrack to find additions, deletions, and matches
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && user[i - 1].toLowerCase() == correct[j - 1].toLowerCase()) {
        result.insert(0, DiffSegment(DiffType.match, correct[j - 1]));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
        // Character is in correct spelling but not user input (missing)
        result.insert(0, DiffSegment(DiffType.missing, correct[j - 1]));
        j--;
      } else {
        // Character is in user input but not correct spelling (extra)
        result.insert(0, DiffSegment(DiffType.extra, user[i - 1]));
        i--;
      }
    }

    // Merge consecutive segments of the same DiffType
    final List<DiffSegment> merged = [];
    if (result.isNotEmpty) {
      var currentType = result[0].type;
      var currentText = StringBuffer(result[0].text);
      
      for (int idx = 1; idx < result.length; idx++) {
        if (result[idx].type == currentType) {
          currentText.write(result[idx].text);
        } else {
          merged.add(DiffSegment(currentType, currentText.toString()));
          currentType = result[idx].type;
          currentText = StringBuffer(result[idx].text);
        }
      }
      merged.add(DiffSegment(currentType, currentText.toString()));
    }

    return merged;
  }
}
