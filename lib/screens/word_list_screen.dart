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
          IconButton(
            icon: const Icon(Icons.file_upload, color: Colors.white70),
            tooltip: '批量匯入',
            onPressed: () => _showBulkImportDialog(),
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
                                        _buildTagChip('反 x${word.antonyms.length}', const Color(0xFFFF3366)),
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
                                      _buildTagChip('反義詞 x${word.antonyms.length}', const Color(0xFFFF3366)),
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
    final sentenceController = TextEditingController(text: word?.sampleSentence ?? '');
    bool isAutoQuerying = false;
    
    List<String> synonyms = word?.synonyms ?? [];
    List<String> antonyms = word?.antonyms ?? [];

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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextFormField(
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
                            ),
                            if (word == null) ...[
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: isAutoQuerying 
                                    ? null 
                                    : () async {
                                        final text = wordController.text.trim();
                                        if (text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('請先輸入英文單字！')),
                                          );
                                          return;
                                        }
                                        setState(() {
                                          isAutoQuerying = true;
                                        });
                                        try {
                                          final result = await DictionaryLookupService.lookup(text);
                                          setState(() {
                                            defController.text = result.definition;
                                            synonyms = result.synonyms;
                                            antonyms = result.antonyms;
                                            if (result.sampleSentence != null) {
                                              sentenceController.text = result.sampleSentence!;
                                            }
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('自動查詢成功！')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('自動查詢失敗: $e')),
                                          );
                                        } finally {
                                          setState(() {
                                            isAutoQuerying = false;
                                          });
                                        }
                                      },
                                icon: isAutoQuerying 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.auto_awesome, size: 16),
                                label: const Text('自動生成'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00FFCC),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ],
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
                        const SizedBox(height: 20),
                        
                        // Synonyms Chip Input
                        SynonymInput(
                          initialTags: synonyms,
                          label: '同義字 (至少 3 個)',
                          hint: '輸入單字後按逗號、空格或Enter新增',
                          accentColor: const Color(0xFF9966FF),
                          onChanged: (tags) {
                            synonyms = tags;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Antonyms Chip Input
                        SynonymInput(
                          initialTags: antonyms,
                          label: '反義字 (至少 2 個)',
                          hint: '輸入單字後按逗號、空格或Enter新增',
                          accentColor: const Color(0xFFFF3366),
                          onChanged: (tags) {
                            antonyms = tags;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Sentence Field
                        TextFormField(
                          controller: sentenceController,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: '造句 / 例句 (選填)',
                            labelStyle: TextStyle(color: Colors.white60),
                            border: OutlineInputBorder(),
                            hintText: '例：The hotel can accommodate guests.',
                          ),
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
                      if (synonyms.length < 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('需要至少 3 個同義字！')),
                        );
                        return;
                      }
                      if (antonyms.length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('需要至少 2 個反義字！')),
                        );
                        return;
                      }

                      final provider = context.read<WordsProvider>();
                      if (word == null) {
                        // Create
                        provider.addWord(
                          word: wordController.text,
                          definition: defController.text,
                          synonyms: synonyms,
                          antonyms: antonyms,
                          sampleSentence: sentenceController.text.isNotEmpty 
                              ? sentenceController.text 
                              : null,
                        );
                      } else {
                        // Edit
                        final updated = word.copyWith(
                          definition: defController.text,
                          synonyms: synonyms,
                          antonyms: antonyms,
                          sampleSentence: sentenceController.text,
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

                  // Antonyms
                  const Text('反義詞', style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  word.antonyms.isEmpty
                      ? const Text('無', style: TextStyle(color: Colors.white30))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: word.antonyms.map((a) => _buildTagChip(a, const Color(0xFFFF3366))).toList(),
                        ),
                  const Divider(color: Colors.white10, height: 24),

                  // Sample Sentence
                  if (word.sampleSentence != null && word.sampleSentence!.isNotEmpty) ...[
                    const Text('例句', style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
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
                              word.sampleSentence!,
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddEditDialog(word: word);
              },
              child: const Text('編輯單字', style: TextStyle(color: Color(0xFF9966FF))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, {Widget? suffixWidget}) {
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

  void _showBulkImportDialog() {
    String importText = '';
    String formatType = 'csv'; // 'csv' or 'words'
    bool autoQuery = true;
    bool isImporting = false;
    String progressMessage = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131926),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white10),
              ),
              title: const Text('批量匯入單字', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Format selection
                      Row(
                        children: [
                          const Text('匯入格式：', style: TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: formatType,
                            dropdownColor: const Color(0xFF131926),
                            items: const [
                              DropdownMenuItem(value: 'csv', child: Text('管線分隔 (CSV/Text)', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'words', child: Text('純英文單字列表 (一行一個)', style: TextStyle(color: Colors.white))),
                            ],
                            onChanged: isImporting 
                                ? null 
                                : (v) {
                                    if (v != null) {
                                      setState(() {
                                        formatType = v;
                                      });
                                    }
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Format explanation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          formatType == 'csv'
                              ? '格式：單字|定義|同義詞(以逗號分隔)|反義詞(以逗號分隔)|例句(選填)\n例：accommodate|容納|house,hold|exclude,reject|The room can accommodate 5 guests.'
                              : '格式：每行輸入一個英文單字。\n例：\ngregarious\nubiquitous\nephemeral',
                          style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Auto query checkbox (only for word list)
                      if (formatType == 'words') ...[
                        Row(
                          children: [
                            Checkbox(
                              value: autoQuery,
                              activeColor: const Color(0xFF9966FF),
                              onChanged: isImporting 
                                  ? null 
                                  : (v) {
                                      if (v != null) {
                                        setState(() {
                                          autoQuery = v;
                                        });
                                      }
                                    },
                            ),
                            const Text('自動查詢翻譯、同義及反義字', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Large TextField
                      if (!isImporting) ...[
                        TextField(
                          maxLines: 8,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: formatType == 'csv'
                                ? '請在此貼上管線分隔的文字內容...'
                                : '請在此貼上單字列表，一行一個...',
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: const Color(0xFF090D16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white10),
                            ),
                          ),
                          onChanged: (v) {
                            importText = v;
                          },
                        ),
                      ] else ...[
                        // Progress loader
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(color: Color(0xFF9966FF)),
                              const SizedBox(height: 16),
                              Text(
                                progressMessage,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isImporting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isImporting 
                      ? null 
                      : () async {
                          final lines = importText
                              .split('\n')
                              .map((l) => l.trim())
                              .where((l) => l.isNotEmpty)
                              .toList();

                          if (lines.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('請先輸入要匯入的內容！')),
                            );
                            return;
                          }

                          setState(() {
                            isImporting = true;
                            progressMessage = '正在解析資料...';
                          });

                          try {
                            final List<WordModel> wordsToImport = [];

                            if (formatType == 'csv') {
                              for (int i = 0; i < lines.length; i++) {
                                final line = lines[i];
                                final parts = line.split('|');
                                if (parts.length < 4) {
                                  throw Exception('第 ${i + 1} 行格式不符，至少需要：單字|定義|同義詞|反義詞');
                                }
                                final wordText = parts[0].trim();
                                final defText = parts[1].trim();
                                final synonymsList = parts[2]
                                    .split(',')
                                    .map((s) => s.trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList();
                                final antonymsList = parts[3]
                                    .split(',')
                                    .map((a) => a.trim())
                                    .where((a) => a.isNotEmpty)
                                    .toList();
                                final sentence = parts.length > 4 ? parts[4].trim() : null;

                                wordsToImport.add(
                                  WordModel(
                                    word: wordText,
                                    definition: defText,
                                    synonyms: synonymsList,
                                    antonyms: antonymsList,
                                    sampleSentence: sentence,
                                  ),
                                );
                              }
                            } else {
                              // Plain word list
                              for (int i = 0; i < lines.length; i++) {
                                final wordText = lines[i];
                                
                                if (autoQuery) {
                                  setState(() {
                                    progressMessage = '正在自動查詢第 ${i + 1}/${lines.length} 個單字:\n"$wordText"';
                                  });
                                  try {
                                    final result = await DictionaryLookupService.lookup(wordText);
                                    wordsToImport.add(
                                      WordModel(
                                        word: result.word,
                                        definition: result.definition,
                                        synonyms: result.synonyms,
                                        antonyms: result.antonyms,
                                        sampleSentence: result.sampleSentence,
                                      ),
                                    );
                                  } catch (e) {
                                    // Fallback if lookup fails
                                    wordsToImport.add(
                                      WordModel(
                                        word: wordText,
                                        definition: '查詢失敗，請手動修改',
                                        synonyms: [],
                                        antonyms: [],
                                      ),
                                    );
                                  }
                                } else {
                                  // Add empty word details if auto query is disabled
                                  wordsToImport.add(
                                    WordModel(
                                      word: wordText,
                                      definition: '請輸入中文意思',
                                      synonyms: [],
                                      antonyms: [],
                                    ),
                                  );
                                }
                              }
                            }

                            setState(() {
                              progressMessage = '正在將 ${wordsToImport.length} 個單字儲存至單字庫...';
                            });

                            // Bulk add in provider
                            await context.read<WordsProvider>().addWordsBulk(wordsToImport);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('成功匯入 ${wordsToImport.length} 個單字！')),
                            );
                            Navigator.of(dialogContext).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('匯入失敗: $e')),
                            );
                            setState(() {
                              isImporting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9966FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('確認匯入'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
