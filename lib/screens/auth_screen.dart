import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  bool _isEditingConfig = false;

  @override
  void initState() {
    super.initState();
    final supabase = context.read<SupabaseService>();
    _urlController.text = supabase.supabaseUrl ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final supabase = context.watch<SupabaseService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('雲端設定'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: supabase.isConnected 
                          ? const Color(0xFF00FFCC).withOpacity(0.2) 
                          : Colors.white10,
                      radius: 28,
                      child: Icon(
                        supabase.isConnected ? Icons.cloud_done : Icons.cloud_off,
                        color: supabase.isConnected ? const Color(0xFF00FFCC) : Colors.white30,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supabase.isConnected ? '雲端模式已啟動' : '離線本地模式',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            supabase.isConnected 
                                ? (supabase.isAuthenticated 
                                    ? '已登入：${supabase.currentUser?.email}' 
                                    : '已連線至 Supabase，請登入 Google')
                                : '所有單字儲存在此裝置上，可點擊下方設定連線。',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Authentication Action Block
            if (supabase.isConnected) ...[
              const Text(
                '帳號同步',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!supabase.isAuthenticated) ...[
                        const Text(
                          '登入 Google 帳號，即可在不同的手機與電腦之間無縫同步您的所有單字與學習記錄。',
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final success = await supabase.signInWithGoogle();
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('登入失敗，請檢查瀏覽器彈出視窗設定或驗證配置。')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9966FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.login),
                          label: const Text('使用 Google 帳號登入', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(supabase.currentUser?.email ?? 'Google 帳戶'),
                          subtitle: const Text('已啟用雙向即時雲端同步'),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF9966FF),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await supabase.signOut();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF3366),
                            side: const BorderSide(color: Color(0xFFFF3366)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text('登出帳號'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditingConfig = true;
                          });
                        },
                        child: const Text('修改 Supabase 連線資訊', style: TextStyle(color: Colors.white30)),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (!supabase.isConnected || _isEditingConfig) ...[
              const Text(
                'Supabase 連線設定',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '請輸入您的 Supabase 專案 API 資訊以啟用雲端同步：',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        
                        // URL Input
                        TextFormField(
                          controller: _urlController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Supabase URL',
                            hintText: 'https://xxxx.supabase.co',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入 URL' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Anon Key Input
                        TextFormField(
                          controller: _keyController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Supabase Anon Key (或 Service Role Key)',
                            hintText: 'eyJhbGciOi...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入 Anon Key' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        ElevatedButton(
                          onPressed: supabase.isConnecting
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    final success = await supabase.connect(
                                      _urlController.text.trim(),
                                      _keyController.text.trim(),
                                    );
                                    if (success) {
                                      setState(() {
                                        _isEditingConfig = false;
                                      });
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('連線失敗，請檢查 URL 與 Key。')),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FFCC),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: supabase.isConnecting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Text('連線並儲存', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        
                        if (_isEditingConfig) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditingConfig = false;
                              });
                            },
                            child: const Text('取消修改', style: TextStyle(color: Colors.white54)),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '如何設定？',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. 註冊並登入 Supabase (supabase.com)。', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      SizedBox(height: 6),
                      Text('2. 點擊「New Project」建立一個新專案。', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      SizedBox(height: 6),
                      Text('3. 專案建立完成後，至 Settings -> API 複製 URL 與 Project API key (anon-public)。', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      SizedBox(height: 6),
                      Text('4. 在 SQL Editor 執行專案中 supabase/schema.sql 來初始化資料庫表單。', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      SizedBox(height: 6),
                      Text('5. 啟用 Google OAuth（在 Authentication -> Providers -> Google 設定中綁定您的 Client ID 與 Secret 即可）。', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }
}
