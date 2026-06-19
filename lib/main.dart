import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'services/words_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/word_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final storageService = await StorageService.init();
  final supabaseService = SupabaseService(storageService);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: supabaseService),
        ChangeNotifierProvider(
          create: (_) => WordsProvider(storageService, supabaseService),
        ),
      ],
      child: const LingoGlowApp(),
    ),
  );
}

class LingoGlowApp extends StatelessWidget {
  const LingoGlowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LingoGlow',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        primaryColor: const Color(0xFF9966FF), // Neon Purple
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9966FF),
          secondary: Color(0xFF00FFCC), // Neon Cyan
          surface: Color(0xFF131926),
          error: Color(0xFFFF3366), // Neon Pink/Red
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyLarge: const TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF131926),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          elevation: 8,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF090D16),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF131926),
          selectedItemColor: Color(0xFF9966FF),
          unselectedItemColor: Colors.white30,
          elevation: 10,
        ),
      ),
      home: const MainAppShell(),
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({Key? key}) : super(key: key);

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const WordListScreen(),
    const AuthScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                // Desktop Sidebar Navigation
                Container(
                  width: 240,
                  decoration: const BoxDecoration(
                    color: Color(0xFF131926),
                    border: Border(right: BorderSide(color: Colors.white10)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Logo / Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/logo.png', width: 40, height: 40, errorBuilder: (_, __, ___) => 
                              const Icon(Icons.menu_book, color: Color(0xFF00FFCC), size: 36)),
                          const SizedBox(width: 12),
                          const Text(
                            'LingoGlow',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _SidebarItem(
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard,
                        label: '學習主頁',
                        isSelected: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      _SidebarItem(
                        icon: Icons.list_alt_outlined,
                        selectedIcon: Icons.list_alt,
                        label: '單字庫',
                        isSelected: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _SidebarItem(
                        icon: Icons.cloud_queue_outlined,
                        selectedIcon: Icons.cloud_done,
                        label: '雲端同步',
                        isSelected: _currentIndex == 2,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                      _SidebarItem(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings,
                        label: '設定',
                        isSelected: _currentIndex == 3,
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'v1.0.0 • Spaced Repetition',
                          style: TextStyle(color: Colors.white24, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Screen Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _screens[_currentIndex],
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                _screens[_currentIndex],
              ],
            ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: '主頁',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_outlined),
                  activeIcon: Icon(Icons.list_alt),
                  label: '單字庫',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.cloud_queue_outlined),
                  activeIcon: Icon(Icons.cloud_done),
                  label: '雲端',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: '設定',
                ),
              ],
            ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    Key? key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? activeColor : Colors.white54,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
