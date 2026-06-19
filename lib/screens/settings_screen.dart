import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/words_provider.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = context.watch<SupabaseService>();
    final wordsProvider = context.watch<WordsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // App Header
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      color: const Color(0xFF131926),
                      child: const Icon(Icons.menu_book, color: Color(0xFF00FFCC), size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'LingoGlow',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  '間隔重複單字訓練 APP',
                  style: TextStyle(color: Colors.white30, fontSize: 13),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),

          // System Info Block
          const Text(
            '系統統計',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('單字庫容量'),
                  trailing: Text(
                    '${wordsProvider.totalCount} 個單字',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: const Text('已熟記比例'),
                  trailing: Text(
                    wordsProvider.totalCount > 0
                        ? '${((wordsProvider.masteredCount / wordsProvider.totalCount) * 100).toStringAsFixed(1)}%'
                        : '0.0%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: const Text('今日需複習'),
                  trailing: Text(
                    '${wordsProvider.dueCount} 個單字',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: wordsProvider.dueCount > 0 ? const Color(0xFFFF3366) : const Color(0xFF00FFCC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cloud Sync Info Block
          const Text(
            '儲存與連線',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('連線狀態'),
                  subtitle: Text(supabase.isConnected ? '雲端同步中' : '僅儲存於此裝置'),
                  trailing: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: supabase.isConnected ? const Color(0xFF00FFCC) : Colors.white24,
                    ),
                  ),
                ),
                if (supabase.isConnected) ...[
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    title: const Text('中斷 Supabase 連線'),
                    subtitle: const Text('清除已儲存的專案 API 連線資訊'),
                    trailing: const Icon(Icons.link_off, color: Color(0xFFFF3366)),
                    onTap: () {
                      _confirmDisconnect(context, supabase);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Block
          const Text(
            '關於',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('軟體版本'),
                  trailing: Text('v1.0.0'),
                ),
                Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: Text('技術支援'),
                  trailing: Text('Flutter & Supabase'),
                ),
                Divider(height: 1, color: Colors.white10),
                ListTile(
                  title: Text('開發商'),
                  trailing: Text('Antigravity Pair'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, SupabaseService supabase) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('中斷雲端連線'),
          content: const Text('您確定要中斷與 Supabase 的連線並清除 API 金鑰嗎？\n中斷後將返回離線模式，已儲存於本地的單字不受影響。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                await supabase.disconnect();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('確定中斷', style: TextStyle(color: Color(0xFFFF3366))),
            ),
          ],
        );
      },
    );
  }
}
