import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/word.dart';
import '../models/topic.dart';
import '../services/db_service.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../services/pdf_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final ApiService _api = ApiService();
  late final SyncService _syncService;
  final PdfService _pdf = PdfService();

  // State lists
  List<Word> _words = [];
  List<Topic> _topics = [];
  List<Word> _flashcardWords = []; // Independent list for flashcard practices
  List<String> _errorLogs = []; // Global system error logs

  // Theme State
  bool _isDarkMode = false;

  // Network State
  bool _isOnline = true;
  bool _isMockOffline = false; // Allows user to manually test offline state in UI
  bool _isSyncing = false;

  // Translate State
  String _translateInput = '';
  String _translateOutput = '';
  bool _isTranslating = false;
  bool _isEnglishToTurkish = true; // Translation direction flag

  // Writing Module State
  Topic? _currentWritingTopic;
  int _writingWordCount = 5;
  List<Word> _selectedWritingWords = [];
  bool _isLoadingTopics = false;

  // Getters
  List<Word> get words => _words;
  List<Topic> get topics => _topics;
  List<Word> get flashcardWords => _flashcardWords;
  List<String> get errorLogs => _errorLogs;
  bool get isDarkMode => _isDarkMode;
  bool get isOnline => _isOnline && !_isMockOffline;
  bool get isMockOffline => _isMockOffline;
  bool get isSyncing => _isSyncing;
  
  String get translateInput => _translateInput;
  String get translateOutput => _translateOutput;
  bool get isTranslating => _isTranslating;
  bool get isEnglishToTurkish => _isEnglishToTurkish;

  Topic? get currentWritingTopic => _currentWritingTopic;
  int get writingWordCount => _writingWordCount;
  List<Word> get selectedWritingWords => _selectedWritingWords;
  bool get isLoadingTopics => _isLoadingTopics;

  AppState() {
    _syncService = SyncService(
      onSyncComplete: _onSyncComplete,
      onError: (err) => logError(err),
    );
    _init();
  }

  // --- Monospace Logger Core API ---

  void logError(String message) {
    final now = DateTime.now();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    _errorLogs.add("[$timeString] $message");
    notifyListeners();
  }

  void clearLogs() {
    _errorLogs.clear();
    notifyListeners();
  }

  Future<void> _init() async {
    try {
      // 1. Check current connection
      final connectivityResults = await Connectivity().checkConnectivity();
      _isOnline = connectivityResults.isNotEmpty && 
                  connectivityResults.any((result) => result != ConnectivityResult.none);
      
      // Start listening to real network changes
      _syncService.startListening();

      // 2. Load database records
      await loadWords();
      await _loadOrSeedTopics();

      // 3. Perform initial sync of pending words if online
      if (isOnline) {
        await _syncPendingWords();
      }
    } catch (e) {
      logError("App initialization failed: $e");
    }
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  // --- Network & Sync Settings ---

  void toggleMockOffline() {
    _isMockOffline = !_isMockOffline;
    notifyListeners();
    
    if (isOnline) {
      // If we went online, trigger synchronization
      _syncPendingWords();
    }
  }

  void _onSyncComplete() {
    loadWords();
  }

  Future<void> _syncPendingWords() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    await _syncService.syncPendingWords();

    _isSyncing = false;
    notifyListeners();
  }

  // --- Vocabulary / Words Operations ---

  Future<void> loadWords() async {
    try {
      _words = await _db.getWords();
      _flashcardWords = List<Word>.from(_words);
      notifyListeners();
    } catch (e) {
      logError("Database loadWords failed: $e");
    }
  }

  Future<void> addWordManually(String english, String turkish) async {
    if (english.trim().isEmpty || turkish.trim().isEmpty) return;

    final wordEnglish = english.trim();
    final wordTurkish = turkish.trim();

    try {
      if (isOnline) {
        // Fetch phonetic online
        String phonetic = '';
        try {
          phonetic = await _api.fetchPhonetic(wordEnglish);
        } catch (e) {
          logError("Phonetics API fetch failed for '$wordEnglish': $e");
        }
        final word = Word(
          english: wordEnglish,
          turkish: wordTurkish,
          phonetic: phonetic,
          syncStatus: 'synced',
        );
        await _db.insertWord(word);
      } else {
        // Offline mode: save blank phonetic with 'pending' status
        final word = Word(
          english: wordEnglish,
          turkish: wordTurkish,
          phonetic: '',
          syncStatus: 'pending',
        );
        await _db.insertWord(word);
      }
      await loadWords();
    } catch (e) {
      logError("Database addWord failed for '$wordEnglish': $e");
    }
  }

  Future<void> updateWord(Word word) async {
    try {
      await _db.updateWord(word);
      await loadWords();
    } catch (e) {
      logError("Database updateWord failed for '${word.english}': $e");
    }
  }

  Future<void> deleteWord(int id) async {
    try {
      await _db.deleteWord(id);
      // If deleted word was selected in writing, remove it from that selection
      _selectedWritingWords.removeWhere((w) => w.id == id);
      await loadWords();
    } catch (e) {
      logError("Database deleteWord failed for ID $id: $e");
    }
  }

  // --- Translation Operations ---

  void setTranslateInput(String value) {
    _translateInput = value;
    if (_translateInput.isEmpty) {
      _translateOutput = '';
    }
    notifyListeners();
  }

  void toggleTranslationDirection() {
    _isEnglishToTurkish = !_isEnglishToTurkish;
    final temp = _translateInput;
    _translateInput = _translateOutput;
    _translateOutput = temp;
    notifyListeners();
  }

  Future<void> translate() async {
    if (!isOnline || _translateInput.trim().isEmpty) return;

    _isTranslating = true;
    notifyListeners();

    try {
      final result = await _api.translate(_translateInput, isEnglishToTurkish: _isEnglishToTurkish);
      _translateOutput = result;
    } catch (e) {
      logError("Translation failed for '${_translateInput}': $e");
      _translateOutput = '';
    }

    _isTranslating = false;
    notifyListeners();
  }

  Future<void> addTranslationToLibrary() async {
    if (_translateInput.isEmpty || _translateOutput.isEmpty) return;

    // Map correctly: English to the english column, Turkish to the turkish column
    final english = _isEnglishToTurkish ? _translateInput : _translateOutput;
    final turkish = _isEnglishToTurkish ? _translateOutput : _translateInput;

    // Reset input fields
    _translateInput = '';
    _translateOutput = '';
    notifyListeners();

    // Save using the standard add workflow (handles online/offline and duplicate checks)
    await addWordManually(english, turkish);
  }

  // --- PDF Export Operation ---

  Future<File?> exportLibraryToPdf(String directoryPath) async {
    if (_words.isEmpty) return null;
    try {
      return await _pdf.generateVocabularyPdf(_words, directoryPath);
    } catch (e) {
      logError("PDF Generation failed: $e");
      return null;
    }
  }

  // --- Theme Toggle Operation ---

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // --- Flashcard Shuffling ---

  void shuffleFlashcards() {
    _flashcardWords.shuffle();
    notifyListeners();
  }

  // --- Writing Module Operations (Delta-Update Logic) ---

  Future<void> _loadOrSeedTopics() async {
    try {
      _topics = await _db.getTopics();
      if (_topics.isEmpty) {
        // Seed initial topics locally to start offline
        final initialTopics = [
          Topic(id: 'tech_intro', name: 'Introduce how technology affects your daily life', category: 'Technology'),
          Topic(id: 'cooking', name: 'Describe your favorite recipe and how to prepare it', category: 'Food'),
          Topic(id: 'travel_story', name: 'Write about a memorable holiday destination', category: 'Travel'),
          Topic(id: 'hobbies_detail', name: 'How do you spend your free time and why is it beneficial?', category: 'Personal'),
          Topic(id: 'sports_health', name: 'Explain the importance of regular exercise', category: 'Health'),
        ];
        await _db.replaceTopics(initialTopics);
        _topics = initialTopics;
      }
      notifyListeners();
    } catch (e) {
      logError("Database load/seed topics failed: $e");
    }
  }

  /// Sets word count N directly or via increment/decrement
  void setWritingWordCount(int count) {
    if (count < 1) return;
    _writingWordCount = count;
    notifyListeners();
  }

  /// Refreshes/Fetches topics from the online source and overwrites a portion of old cached topics.
  Future<void> refreshTopicsOnline() async {
    if (!isOnline) return;

    _isLoadingTopics = true;
    notifyListeners();

    try {
      final freshTopics = await _api.fetchOnlineTopics();
      if (freshTopics.isNotEmpty) {
        // Overwrite a portion: keep 3 random current topics, replace the rest
        final currentTopicsCopy = List<Topic>.from(_topics)..shuffle();
        final keptTopics = currentTopicsCopy.take(min(3, currentTopicsCopy.length)).toList();
        
        final combined = [...keptTopics, ...freshTopics];
        
        // Update DB and Memory state
        await _db.replaceTopics(combined);
        _topics = combined;
      }
    } catch (e) {
      logError("Topics online fetch failed: $e");
    }

    _isLoadingTopics = false;
    notifyListeners();
  }

  /// Generates a completely new prompt: fetches a new random topic and N random words.
  void generateNewWritingPrompt() {
    if (_topics.isEmpty || _words.isEmpty) {
      _currentWritingTopic = null;
      _selectedWritingWords = [];
      notifyListeners();
      return;
    }

    // 1. Pick a random topic
    final random = Random();
    _currentWritingTopic = _topics[random.nextInt(_topics.length)];

    // 2. Select N random words from the Library
    final wordsCopy = List<Word>.from(_words)..shuffle();
    final count = min(_writingWordCount, wordsCopy.length);
    _selectedWritingWords = wordsCopy.take(count).toList();

    notifyListeners();
  }

  /// Updates the writing prompt words list without changing the topic.
  /// Follows the delta-update algorithm:
  /// - If N increases: Keep existing words, randomly pick additional library words to reach N.
  /// - If N decreases: Keep existing, but remove items from the end of the list to match N.
  void updateWritingWordsOnly() {
    if (_currentWritingTopic == null || _words.isEmpty) return;

    final currentLength = _selectedWritingWords.length;
    final targetLength = min(_writingWordCount, _words.length);

    if (targetLength == currentLength) return;

    if (targetLength > currentLength) {
      // Increase N: Keep existing, select additional new words
      final existingIds = _selectedWritingWords.map((w) => w.id).toSet();
      
      // Filter out library words that are already in our selected list
      final availableWords = _words.where((w) => !existingIds.contains(w.id)).toList();
      
      if (availableWords.isNotEmpty) {
        availableWords.shuffle();
        final additionalNeeded = targetLength - currentLength;
        final count = min(additionalNeeded, availableWords.length);
        
        final addedWords = availableWords.take(count).toList();
        _selectedWritingWords = [..._selectedWritingWords, ...addedWords];
      }
    } else {
      // Decrease N: Truncate from the end
      _selectedWritingWords = _selectedWritingWords.sublist(0, targetLength);
    }

    notifyListeners();
  }
}
