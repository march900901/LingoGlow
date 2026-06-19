import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_model.dart';
import '../services/words_provider.dart';
import '../widgets/synonym_input.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({Key? key}) : super(key: key);

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredWords.length,
                    itemBuilder: (context, index) {
                      final word = filteredWords[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
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
}
