import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'translate_view.dart';
import 'library_view.dart';
import 'flashcards_view.dart';
import 'writing_view.dart';
import 'settings_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  final List<Widget> _views = const [
    TranslateView(),
    LibraryView(),
    FlashcardsView(),
    WritingView(),
    SettingsView(),
  ];

  final List<String> _titles = const [
    'Translate',
    'Library',
    'Flashcards',
    'Writing Prompt',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final online = state.isOnline;
        final mockOffline = state.isMockOffline;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: state.isDarkMode ? Colors.grey[900] : Colors.white,
            elevation: 0.5,
            title: Text(
              _titles[_currentTabIndex],
              style: TextStyle(
                color: state.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              // Shuffle button for Flashcards
              if (_currentTabIndex == 2 && state.flashcardWords.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: state.isDarkMode ? Colors.indigo[200] : Colors.indigo[800],
                  ),
                  tooltip: 'Shuffle Flashcards',
                  onPressed: () {
                    state.shuffleFlashcards();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Flashcards shuffled!'),
                        duration: Duration(milliseconds: 1000),
                      ),
                    );
                  },
                ),
              // Sync Indicator
              if (state.isSyncing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                      ),
                    ),
                  ),
                ),

              // Network Status Indicator Pill
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: online ? Colors.teal[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: online ? Colors.teal[200]! : Colors.orange[200]!,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: 14,
                      color: online ? Colors.teal[700] : Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      online ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: online ? Colors.teal[700] : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Mock Connection Toggle Button
              IconButton(
                icon: Icon(
                  mockOffline ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
                  color: mockOffline ? Colors.teal : Colors.grey[600],
                ),
                tooltip: mockOffline ? 'Reconnect Network' : 'Mock Offline State',
                onPressed: () {
                  state.toggleMockOffline();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.isMockOffline 
                            ? 'Simulating Offline Mode. Translation and phonetic fetches are disabled.' 
                            : 'Reconnected to network. Background synchronization triggered.',
                      ),
                      duration: const Duration(seconds: 3),
                      backgroundColor: state.isMockOffline ? Colors.orange[800] : Colors.teal[800],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _currentTabIndex,
              children: _views,
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: state.isDarkMode ? Colors.grey[900] : Colors.white,
            selectedItemColor: state.isDarkMode ? Colors.indigo[200] : Colors.indigo[800],
            unselectedItemColor: Colors.grey[500],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.translate),
                activeIcon: Icon(Icons.translate_rounded),
                label: 'Translate',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_border_rounded),
                activeIcon: Icon(Icons.bookmark_rounded),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.style_outlined),
                activeIcon: Icon(Icons.style_rounded),
                label: 'Flashcards',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_note_outlined),
                activeIcon: Icon(Icons.edit_note_rounded),
                label: 'Writing',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
