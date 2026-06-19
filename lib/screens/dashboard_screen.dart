import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/words_provider.dart';
import 'review_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final wordsProvider = context.watch<WordsProvider>();
    final dueCount = wordsProvider.dueCount;
    final totalCount = wordsProvider.totalCount;
    final masteredCount = wordsProvider.masteredCount;
    
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LingoGlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF00FFCC)),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('正在與雲端同步...'), duration: Duration(seconds: 1)),
              );
              await wordsProvider.syncWithCloud();
            },
            tooltip: '同步雲端',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              const Text(
                '您好, 學習者!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '利用間隔重複演算法 (SRS) 來加深單字記憶吧。',
                style: TextStyle(color: Colors.white60, fontSize: 15),
              ),
              const SizedBox(height: 28),

              // Glowing Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C2BFF), Color(0xFF9966FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9966FF).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日需複習單字',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$dueCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: dueCount > 0
                          ? () {
                              wordsProvider.startReviewSession();
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ReviewScreen()),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FFCC), // Neon Cyan
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white10,
                        disabledForegroundColor: Colors.white30,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(dueCount > 0 ? Icons.play_arrow : Icons.check_circle_outline),
                          const SizedBox(width: 8),
                          Text(
                            dueCount > 0 ? '進入複習領域' : '今日已完成複習',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Statistics grid
              const Text(
                '統計數據',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.6 : 1.3,
                children: [
                  _buildStatTile(
                    context,
                    title: '單字總數',
                    value: '$totalCount',
                    icon: Icons.menu_book,
                    color: const Color(0xFF00FFCC),
                  ),
                  _buildStatTile(
                    context,
                    title: '已熟記單字',
                    value: '$masteredCount',
                    icon: Icons.military_tech,
                    color: Colors.amberAccent,
                  ),
                  _buildStatTile(
                    context,
                    title: '未複習單字',
                    value: '${totalCount - dueCount}',
                    icon: Icons.hourglass_empty,
                    color: const Color(0xFFFF3366),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
