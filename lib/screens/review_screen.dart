import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_model.dart';
import '../services/words_provider.dart';
import '../services/diff_service.dart';
import '../services/dictionary.dart';
import '../widgets/diff_text.dart';
import '../widgets/synonym_input.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _currentStep = 0; // 0: Spelling, 1: Synonyms/Antonyms, 2: Sentence, 3: Flashcard rating

  // Spelling controller
  final TextEditingController _spellingController = TextEditingController();
  bool _spellingChecked = false;
  bool _spellingCorrect = false;
  List<DiffSegment> _spellingDiff = [];

  // Synonyms controllers
  List<String> _userSynonyms = [];
  List<String> _userAntonyms = [];
  bool _synsChecked = false;
  bool _synsSufficient = true;

  // Sentence controller
  final TextEditingController _sentenceController = TextEditingController();
  bool _sentenceChecked = false;
  bool _sentenceCorrect = false;
  String _sentenceErrorMsg = '';
  List<Widget> _sentenceSpans = [];

  void _resetStepState() {
    _currentStep = 0;
    
    _spellingController.clear();
    _spellingChecked = false;
    _spellingCorrect = false;
    _spellingDiff = [];

    _userSynonyms = [];
    _userAntonyms = [];
    _synsChecked = false;
    _synsSufficient = true;

    _sentenceController.clear();
    _sentenceChecked = false;
    _sentenceCorrect = false;
    _sentenceErrorMsg = '';
    _sentenceSpans = [];
  }

  void _checkSpelling(String correctWord) {
    final input = _spellingController.text.trim();
    if (input.toLowerCase() == correctWord.toLowerCase()) {
      setState(() {
        _spellingCorrect = true;
        _spellingChecked = true;
      });
    } else {
      setState(() {
        _spellingCorrect = false;
        _spellingChecked = true;
        _spellingDiff = DiffService.diffStrings(input, correctWord);
      });
    }
  }

  void _checkSynonyms(WordModel word) {
    setState(() {
      _synsChecked = true;
      _synsSufficient = _userSynonyms.length >= 3 && _userAntonyms.length >= 2;
    });
  }

  void _checkSentence(String targetWord) {
    final sentence = _sentenceController.text.trim();
    if (sentence.isEmpty) {
      setState(() {
        _sentenceCorrect = false;
        _sentenceChecked = true;
        _sentenceErrorMsg = '請輸入造句。';
      });
      return;
    }

    // Split sentence into words
    final words = sentence.split(RegExp(r'\s+'));
    bool foundTarget = false;
    bool spellingError = false;
    final List<Widget> spans = [];

    // Parse root of target word (basic prefix lookup)
    final targetRoot = targetWord.length > 4 ? targetWord.substring(0, targetWord.length - 2).toLowerCase() : targetWord.toLowerCase();

    for (var rawWord in words) {
      // Clean word to check
      final cleaned = Dictionary.cleanWord(rawWord);
      if (cleaned.isEmpty) {
        spans.add(Text(rawWord + ' ', style: const TextStyle(fontSize: 16)));
        continue;
      }

      // Check if it's the target word (or inflection)
      bool isTarget = false;
      if (cleaned.startsWith(targetRoot) || cleaned == targetWord.toLowerCase()) {
        foundTarget = true;
        isTarget = true;
      }

      // Spell check other words
      bool isValidSpell = Dictionary.checkSpelling(cleaned, additionalAcceptedWords: [targetWord]);

      if (isTarget) {
        // Verify target word spelling inside sentence
        final isExactInflection = cleaned.startsWith(targetRoot);
        if (isExactInflection) {
          spans.add(Text(
            rawWord + ' ',
            style: const TextStyle(
              color: Color(0xFF00FFCC),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ));
        } else {
          spellingError = true;
          spans.add(Text(
            rawWord + ' ',
            style: const TextStyle(
              color: Color(0xFFFF3366),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: TextDecoration.lineThrough,
            ),
          ));
        }
      } else if (!isValidSpell) {
        spellingError = true;
        spans.add(Tooltip(
          message: '未識別單字/拼字疑似錯誤',
          child: Text(
            rawWord + ' ',
            style: const TextStyle(
              color: Color(0xFFFF3366),
              fontSize: 16,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFFFF3366),
              decorationStyle: TextDecorationStyle.wavy,
            ),
          ),
        ));
      } else {
        spans.add(Text(rawWord + ' ', style: const TextStyle(fontSize: 16)));
      }
    }

    setState(() {
      _sentenceChecked = true;
      _sentenceSpans = spans;
      if (!foundTarget) {
        _sentenceCorrect = false;
        _sentenceErrorMsg = '造句中必須包含目標單字 "$targetWord"。';
      } else if (spellingError) {
        _sentenceCorrect = false;
        _sentenceErrorMsg = '造句中含有拼字錯誤 (已紅線標示)。';
      } else {
        _sentenceCorrect = true;
        _sentenceErrorMsg = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WordsProvider>();
    
    // Check if session ended
    if (!provider.isSessionActive) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF00FFCC),
                  radius: 36,
                  child: Icon(Icons.stars, color: Colors.black, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  '恭喜完成複習！',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  '間隔重複演算法已重新安排您的複習時程。',
                  style: TextStyle(color: Colors.white54, fontSize: 15),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9966FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('返回主頁', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final word = provider.currentReviewWord!;
    final queue = provider.reviewQueue;
    final index = provider.currentQueueIndex;
    final progress = queue.isNotEmpty ? (index / queue.length) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('複習模式 (${index + 1}/${queue.length})'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            provider.endReviewSession();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Linear Progress Indicator
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9966FF)),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Exercise Steps Indicator
                      _buildStepsIndicator(),
                      const SizedBox(height: 28),
                      
                      // Active Step View
                      if (_currentStep == 0) _buildSpellingStep(word),
                      if (_currentStep == 1) _buildSynonymsStep(word),
                      if (_currentStep == 2) _buildSentenceStep(word),
                      if (_currentStep == 3) _buildRatingStep(word),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, '拼字'),
        _buildStepLine(0),
        _buildStepDot(1, '同反義'),
        _buildStepLine(1),
        _buildStepDot(2, '造句'),
        _buildStepLine(2),
        _buildStepDot(3, '評分'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;
    
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone 
              ? const Color(0xFF00FFCC) 
              : (isActive ? const Color(0xFF9966FF) : Colors.white10),
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.black)
              : Text(
                  '${step + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white30,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.white : Colors.white30,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        )
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isDone = _currentStep > afterStep;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: isDone ? const Color(0xFF00FFCC) : Colors.white10,
    );
  }

  // --- Step 1: Spelling View ---
  Widget _buildSpellingStep(WordModel word) {
    // Blank target word in sample sentence
    String blankedSentence = '無提供例句';
    if (word.sampleSentence != null && word.sampleSentence!.isNotEmpty) {
      final regex = RegExp(word.word, caseSensitive: false);
      blankedSentence = word.sampleSentence!.replaceAll(regex, '______');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '請拼寫出符合定義的單字：',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 16),
        Text(
          word.definition,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '例句：$blankedSentence',
          style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        TextField(
          controller: _spellingController,
          enabled: !_spellingChecked || !_spellingCorrect,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: '輸入英文單字...',
            filled: true,
            fillColor: Colors.black12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _checkSpelling(word.word),
        ),
        const SizedBox(height: 20),

        if (_spellingChecked) ...[
          if (_spellingCorrect)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00FFCC)),
                SizedBox(width: 8),
                Text('拼寫正確！', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
          else ...[
            const Text(
              '拼寫錯誤！字元對比分析：',
              style: TextStyle(color: Color(0xFFFF3366), fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Center(child: DiffText(segments: _spellingDiff)),
            const SizedBox(height: 6),
            const Text(
              '(綠色：正確 | 紅色刪除線：多餘字元 | 黃色底線：缺失字元)',
              style: TextStyle(color: Colors.white30, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 28),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_spellingChecked && !_spellingCorrect)
              TextButton(
                onPressed: () {
                  setState(() {
                    _spellingController.text = word.word;
                    _spellingCorrect = true;
                  });
                },
                child: const Text('顯示答案', style: TextStyle(color: Colors.white54)),
              )
            else
              const SizedBox(),
            
            ElevatedButton(
              onPressed: _spellingChecked && _spellingCorrect
                  ? () => setState(() => _currentStep = 1)
                  : () => _checkSpelling(word.word),
              style: ElevatedButton.styleFrom(
                backgroundColor: _spellingChecked && _spellingCorrect ? const Color(0xFF9966FF) : const Color(0xFF00FFCC),
                foregroundColor: _spellingChecked && _spellingCorrect ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_spellingChecked && _spellingCorrect ? '下一步' : '檢查'),
            ),
          ],
        )
      ],
    );
  }

  // --- Step 2: Synonyms View ---
  Widget _buildSynonymsStep(WordModel word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '請輸入 "${word.word}" 的同反義字：',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 20),
        
        // Synonyms input
        SynonymInput(
          initialTags: _userSynonyms,
          label: '同義字 (目標至少 3 個)',
          hint: _synsChecked ? '已鎖定' : '輸入後按 Enter 或空格',
          accentColor: const Color(0xFF9966FF),
          onChanged: _synsChecked ? (tags) {} : (tags) => _userSynonyms = tags,
        ),
        const SizedBox(height: 20),
        
        // Antonyms input
        SynonymInput(
          initialTags: _userAntonyms,
          label: '反義字 (目標至少 2 個)',
          hint: _synsChecked ? '已鎖定' : '輸入後按 Enter 或空格',
          accentColor: const Color(0xFFFF3366),
          onChanged: _synsChecked ? (tags) {} : (tags) => _userAntonyms = tags,
        ),
        const SizedBox(height: 28),

        if (_synsChecked) ...[
          if (!_synsSufficient)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '輸入的字數不足，已為您顯示參考答案。',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00FFCC)),
                SizedBox(width: 8),
                Text('字數檢驗完成！', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          
          const SizedBox(height: 20),
          const Text('參考解答：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text('建議同義字：${word.synonyms.join(", ")}', style: const TextStyle(color: Color(0xFF9966FF))),
          const SizedBox(height: 4),
          Text('建議反義字：${word.antonyms.join(", ")}', style: const TextStyle(color: Color(0xFFFF3366))),
          const SizedBox(height: 28),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _synsChecked
                  ? () => setState(() => _currentStep = 2)
                  : () => _checkSynonyms(word),
              style: ElevatedButton.styleFrom(
                backgroundColor: _synsChecked ? const Color(0xFF9966FF) : const Color(0xFF00FFCC),
                foregroundColor: _synsChecked ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_synsChecked ? '下一步' : '確認答案'),
            ),
          ],
        )
      ],
    );
  }

  // --- Step 3: Sentence View ---
  Widget _buildSentenceStep(WordModel word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '請使用單字 "${word.word}" 造一個完整的英文句子：',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _sentenceController,
          enabled: !_sentenceChecked || !_sentenceCorrect,
          maxLines: 3,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: '例：The hotel can accommodate guests.',
            border: const OutlineInputBorder(),
            fillColor: Colors.black12,
            filled: true,
          ),
        ),
        const SizedBox(height: 20),

        if (_sentenceChecked) ...[
          if (_sentenceCorrect)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00FFCC)),
                SizedBox(width: 8),
                Text('造句合格！', style: TextStyle(color: Color(0xFF00FFCC), fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
          else ...[
            Text(
              _sentenceErrorMsg,
              style: const TextStyle(color: Color(0xFFFF3366), fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Wrap(
                children: _sentenceSpans,
              ),
            ),
          ],
          const SizedBox(height: 28),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_sentenceChecked && !_sentenceCorrect)
              TextButton(
                onPressed: () {
                  setState(() {
                    _sentenceCorrect = true;
                  });
                },
                child: const Text('略過此步', style: TextStyle(color: Colors.white54)),
              )
            else
              const SizedBox(),
            
            ElevatedButton(
              onPressed: _sentenceChecked && _sentenceCorrect
                  ? () => setState(() => _currentStep = 3)
                  : () => _checkSentence(word.word),
              style: ElevatedButton.styleFrom(
                backgroundColor: _sentenceChecked && _sentenceCorrect ? const Color(0xFF9966FF) : const Color(0xFF00FFCC),
                foregroundColor: _sentenceChecked && _sentenceCorrect ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_sentenceChecked && _sentenceCorrect ? '下一步' : '確認句子'),
            ),
          ],
        )
      ],
    );
  }

  // --- Step 4: Rating / Flashcard View ---
  Widget _buildRatingStep(WordModel word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '練習完成！最後請為本單字記憶度評分：',
          style: TextStyle(color: Colors.white70, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Beautiful Card display
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2336),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF9966FF).withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9966FF).withOpacity(0.1),
                blurRadius: 16,
              )
            ],
          ),
          child: Column(
            children: [
              Text(
                word.word,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                word.definition,
                style: const TextStyle(fontSize: 18, color: Color(0xFF00FFCC)),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              if (word.sampleSentence != null)
                Text(
                  '例句：${word.sampleSentence}',
                  style: const TextStyle(color: Colors.white60, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // 4 Grade Buttons (SM-2 parameters)
        Row(
          children: [
            Expanded(
              child: _buildGradeButton(
                label: '再次挑戰',
                desc: '完全記錯',
                quality: 1,
                color: const Color(0xFFFF3366),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGradeButton(
                label: '困難',
                desc: '勉強想起',
                quality: 2.5.round(), // Map to quality 3
                color: Colors.amberAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGradeButton(
                label: '良好',
                desc: '正常想起',
                quality: 4,
                color: const Color(0xFF9966FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGradeButton(
                label: '簡單',
                desc: '完美反射',
                quality: 5,
                color: const Color(0xFF00FFCC),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildGradeButton({
    required String label,
    required String desc,
    required int quality,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: () {
        context.read<WordsProvider>().rateCurrentWord(quality);
        setState(() {
          _resetStepState();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.12),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: color.withOpacity(0.6), fontSize: 10)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _spellingController.dispose();
    _spellingController.removeListener(() {});
    _sentenceController.dispose();
    super.dispose();
  }
}
