import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_model.dart';
import '../services/words_provider.dart';
import '../widgets/synonym_input.dart';
import '../services/dictionary_lookup_service.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({Key? key}) : super(key: key);

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WordsProvider>();
    final filteredWords = provider.words.where((w) {
      final query = _searchQuery.toLowerCase();
      return w.word.toLowerCase().contains(query) ||
          w.definition.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('單字庫'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white70),
            tooltip: _isGridView ? '列表排版' : '網格排版',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋單字或中文...',
                prefixIcon: const Icon(Icons.search, color: Colors.white30),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF131926),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF9966FF), width: 1.5),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Word List
          Expanded(
            child: filteredWords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? '單字庫為空，請點擊右下角新增單字！' : '找不到符合條件的單字。',
                          style: const TextStyle(color: Colors.white30, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: filteredWords.length,
                        itemBuilder: (context, index) {
                          final word = filteredWords[index];
                          final isMastered = word.repetitions >= 4;
                          return Card(
                            margin: EdgeInsets.zero,
                            child: InkWell(
                              onTap: () => _showWordDetailDialog(word),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            word.word,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        if (isMastered)
                                          const Icon(Icons.stars, color: Colors.amber, size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: Text(
                                        word.definition,
                                        style: const TextStyle(
                                          color: Color(0xFF00FFCC),
                                          fontSize: 13,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _buildTagChip('同 x${word.synonyms.length}', const Color(0xFF9966FF)),
                                        const SizedBox(width: 4),
                                        _buildTagChip('句 x${(word.sampleSentence?.split('\n') ?? []).where((s) => s.isNotEmpty).length}', const Color(0xFF00FFCC)),
                                      ],
                                    ),
                                    const Divider(color: Colors.white10, height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showAddEditDialog(word: word),
                                          child: const Icon(Icons.edit, color: Colors.white70, size: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () => _confirmDelete(word),
                                          child: const Icon(Icons.delete_outline, color: Color(0xFFFF3366), size: 16),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredWords.length,
                        itemBuilder: (context, index) {
                          final word = filteredWords[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () => _showWordDetailDialog(word),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Row(
                                children: [
                                  Text(
                                    word.word,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (word.repetitions >= 4)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                                      ),
                                      child: const Text(
                                        '已熟記',
                                        style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    word.definition,
                                    style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildTagChip('同義詞 x${word.synonyms.length}', const Color(0xFF9966FF)),
                                      const SizedBox(width: 8),
                                      _buildTagChip('例句 x${(word.sampleSentence?.split('\n') ?? []).where((s) => s.isNotEmpty).length}', const Color(0xFF00FFCC)),
                                    ],
                                  )
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                                    onPressed: () => _showAddEditDialog(word: word),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3366), size: 20),
                                    onPressed: () => _confirmDelete(word),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF9966FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTagChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _confirmDelete(WordModel word) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('刪除單字'),
          content: Text('確定要刪除單字 "${word.word}" 嗎？\n此動作無法還原。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                if (word.id != null) {
                  context.read<WordsProvider>().deleteWord(word.id!);
                }
                Navigator.of(context).pop();
              },
              child: const Text('刪除', style: TextStyle(color: Color(0xFFFF3366))),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditDialog({WordModel? word}) {
    final formKey = GlobalKey<FormState>();
    final wordController = TextEditingController(text: word?.word ?? '');
    final defController = TextEditingController(text: word?.definition ?? '');
    
    // Parse existing synonyms (exactly 3)
    final syn1Controller = TextEditingController(
        text: (word != null && word.synonyms.isNotEmpty) ? word.synonyms[0] : '');
    final syn2Controller = TextEditingController(
        text: (word != null && word.synonyms.length > 1) ? word.synonyms[1] : '');
    final syn3Controller = TextEditingController(
        text: (word != null && word.synonyms.length > 2) ? word.synonyms[2] : '');

    // Parse existing sentences (exactly 2)
    final existingSentences = word?.sampleSentence?.split('\n') ?? [];
    final sentence1Controller = TextEditingController(
        text: existingSentences.isNotEmpty ? existingSentences[0] : '');
    final sentence2Controller = TextEditingController(
        text: existingSentences.length > 1 ? existingSentences[1] : '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(word == null ? '新增單字' : '編輯單字'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Word Field
                        TextFormField(
                          controller: wordController,
                          enabled: word == null, // Word cannot be changed on edit
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: '單字 (English)',
                            labelStyle: TextStyle(color: Colors.white60),
                            border: UnderlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入英文單字' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Definition Field
                        TextFormField(
                          controller: defController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: '中文定義 / 翻譯',
                            labelStyle: TextStyle(color: Colors.white60),
                            border: UnderlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入中文定義' : null,
                        ),
                        const SizedBox(height: 24),

                        // Synonyms Header
                        const Text(
                          '同義字 (請輸入 3 個)',
                          style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // Synonym 1
                        TextFormField(
                          controller: syn1Controller,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: '同義字 1',
                            labelStyle: TextStyle(color: Colors.white30, fontSize: 12),
                            border: UnderlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入同義字 1' : null,
                        ),
                        const SizedBox(height: 8),

                        // Synonym 2
                        TextFormField(
                          controller: syn2Controller,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: '同義字 2',
                            labelStyle: TextStyle(color: Colors.white30, fontSize: 12),
                            border: UnderlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入同義字 2' : null,
                        ),
                        const SizedBox(height: 8),

                        // Synonym 3
                        TextFormField(
                          controller: syn3Controller,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: '同義字 3',
                            labelStyle: TextStyle(color: Colors.white30, fontSize: 12),
                            border: UnderlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入同義字 3' : null,
                        ),
                        const SizedBox(height: 24),

                        // Sentences Header
                        const Text(
                          '造句 / 例句 (請輸入 2 個句子)',
                          style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Sentence 1
                        TextFormField(
                          controller: sentence1Controller,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: '句子 1',
                            labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                            border: OutlineInputBorder(),
                            hintText: '輸入包含該單字的完整英文句子 1',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入句子 1' : null,
                        ),
                        const SizedBox(height: 12),

                        // Sentence 2
                        TextFormField(
                          controller: sentence2Controller,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: '句子 2',
                            labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                            border: OutlineInputBorder(),
                            hintText: '輸入包含該單字的完整英文句子 2',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入句子 2' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final provider = context.read<WordsProvider>();
                      final synonymsList = [
                        syn1Controller.text.trim(),
                        syn2Controller.text.trim(),
                        syn3Controller.text.trim(),
                      ];
                      final joinedSentences = '${sentence1Controller.text.trim()}\n${sentence2Controller.text.trim()}';

                      if (word == null) {
                        // Create
                        provider.addWord(
                          word: wordController.text,
                          definition: defController.text,
                          synonyms: synonymsList,
                          antonyms: const <String>[],
                          sampleSentence: joinedSentences,
                        );
                      } else {
                        // Edit
                        final updated = word!.copyWith(
                          definition: defController.text,
                          synonyms: synonymsList,
                          antonyms: const <String>[],
                          sampleSentence: joinedSentences,
                        );
                        provider.updateWord(updated);
                      }

                      Navigator.of(dialogContext).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9966FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('儲存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWordDetailDialog(WordModel word) {
    final nextReviewFormatted = word.nextReviewDate != null 
        ? "${word.nextReviewDate!.year}-${word.nextReviewDate!.month.toString().padLeft(2, '0')}-${word.nextReviewDate!.day.toString().padLeft(2, '0')} ${word.nextReviewDate!.hour.toString().padLeft(2, '0')}:${word.nextReviewDate!.minute.toString().padLeft(2, '0')}"
        : '無';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131926),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white10),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Definition
                  const Text('中文定義', style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    word.definition,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00FFCC),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  // Synonyms
                  const Text('同義詞', style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  word.synonyms.isEmpty
                      ? const Text('無', style: TextStyle(color: Colors.white30))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: word.synonyms.map((s) => _buildTagChip(s, const Color(0xFF9966FF))).toList(),
                        ),
                  const Divider(color: Colors.white10, height: 24),

                  // Sample Sentences
                  if (word.sampleSentence != null && word.sampleSentence!.isNotEmpty) ...[
                    const Text('例句', style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...word.sampleSentence!
                        .split('\n')
                        .where((s) => s.isNotEmpty)
                        .map((sentence) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.format_quote, color: Color(0xFF9966FF), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sentence,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white.withOpacity(0.9),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                    const Divider(color: Colors.white10, height: 24),
                  ],

                  // Learning Stats
                  const Text('學習記憶進度 (SM-2 Spaced Repetition)', style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow('熟練次數 (Repetitions)', '${word.repetitions} 次', suffixWidget: word.repetitions >= 4 ? _buildTagChip('已熟記', Colors.amber) : null),
                        const SizedBox(height: 8),
                        _buildStatRow('複習間隔 (Interval)', '${word.interval} 天'),
                        const SizedBox(height: 8),
                        _buildStatRow('記憶因子 (Ease Factor)', word.easeFactor.toStringAsFixed(2)),
                        const SizedBox(height: 8),
                        _buildStatRow(
                          '下次複習時間', 
                          nextReviewFormatted,
                          suffixWidget: word.isDue 
                              ? _buildTagChip('需複習', const Color(0xFFFF3366))
                              : _buildTagChip('未到期', const Color(0xFF00FFCC)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )  Widget _buildStatRow(String label, String value, {Widget? suffixWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Row(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            if (suffixWidget != null) ...[
              const SizedBox(width: 6),
              suffixWidget,
            ],
          ],
        ),
      ],
    );
  }
}
