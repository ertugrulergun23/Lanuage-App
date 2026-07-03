import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'db_service.dart';
import 'api_service.dart';
import '../models/word.dart';

class SyncService {
  final DatabaseService _db = DatabaseService.instance;
  final ApiService _api = ApiService();
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  
  // Callback to notify the application when a sync completes
  void Function()? onSyncComplete;
  void Function(String message)? onError;

  SyncService({this.onSyncComplete, this.onError});

  /// Starts listening to connectivity changes.
  void startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Check if any of the network interfaces is active (not .none)
      final isOnline = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
      if (isOnline) {
        syncPendingWords();
      }
    });
  }

  /// Stop listening to changes.
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Scans the database for words created offline (pending phonetic)
  /// and fetches their phonetic information from the API.
  Future<void> syncPendingWords() async {
    if (_isSyncing) return;
    
    // Double check connection
    final results = await _connectivity.checkConnectivity();
    final isOnline = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
    if (!isOnline) return;

    _isSyncing = true;

    try {
      final pendingWords = await _db.getPendingSyncWords();
      if (pendingWords.isEmpty) {
        _isSyncing = false;
        return;
      }

      bool hasChanges = false;
      for (var word in pendingWords) {
        // Fetch the phonetic
        final phonetic = await _api.fetchPhonetic(word.english);
        
        // Update the word in the local database
        final updatedWord = word.copyWith(
          phonetic: phonetic,
          syncStatus: 'synced', // Mark as synced even if phonetic is empty to avoid infinite retries
        );
        
        await _db.updateWord(updatedWord);
        hasChanges = true;
      }

      if (hasChanges && onSyncComplete != null) {
        onSyncComplete!();
      }
    } catch (e) {
      if (onError != null) {
        onError!('Phonetics sync failed: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }
}
