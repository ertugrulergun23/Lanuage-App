import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import '../models/word.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({Key? key}) : super(key: key);

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  String _searchQuery = '';

  void _showAddEditWordDialog(BuildContext context, {Word? existingWord}) {
    final state = Provider.of<AppState>(context, listen: false);
    final isDark = state.isDarkMode;
    final englishController = TextEditingController(text: existingWord?.english ?? '');
    final turkishController = TextEditingController(text: existingWord?.turkish ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existingWord == null ? 'Add New Vocabulary' : 'Edit Vocabulary',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.indigo[200] : Colors.indigo[800],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: englishController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'English Word / Sentence',
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: turkishController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Turkish Translation',
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final eng = englishController.text.trim();
                final tur = turkishController.text.trim();
                if (eng.isEmpty || tur.isEmpty) return;

                Navigator.pop(context);

                if (existingWord == null) {
                  // Add New Word - duplicates handled quietly
                  await state.addWordManually(eng, tur);
                } else {
                  // Edit Word
                  final updated = existingWord.copyWith(
                    english: eng,
                    turkish: tur,
                    // If english text changed, reset phonetic and sync status so it syncs again
                    phonetic: eng.toLowerCase() == existingWord.english.toLowerCase() 
                        ? existingWord.phonetic 
                        : '',
                    syncStatus: eng.toLowerCase() == existingWord.english.toLowerCase() 
                        ? existingWord.syncStatus 
                        : 'pending',
                  );
                  await state.updateWord(updated);
                  
                  // Force sync if english text changed and online
                  if (eng.toLowerCase() != existingWord.english.toLowerCase() && state.isOnline) {
                    state.toggleMockOffline(); // Toggles triggers sync
                    state.toggleMockOffline();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.indigo[600] : Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _onExportPdf(BuildContext context, AppState state) async {
    if (state.words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot export empty library. Add words first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Let the user choose the saving directory dynamically
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      // User cancelled picker
      return;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating PDF document...'),
          ],
        ),
      ),
    );

    final file = await state.exportLibraryToPdf(selectedDirectory);

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (file != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: state.isDarkMode ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 40),
            title: Text(
              'PDF Exported Successfully',
              style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black87),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All vocabulary pairs have been exported to a professional PDF file.',
                  style: TextStyle(color: state.isDarkMode ? Colors.grey[300] : Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  'Saved location:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: state.isDarkMode ? Colors.indigo[200] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  file.path,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: state.isDarkMode ? Colors.indigo[200] : Colors.indigo[800],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate PDF.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final isDark = state.isDarkMode;
        
        // Filter words based on search query
        final filteredWords = state.words.where((word) {
          final query = _searchQuery.toLowerCase();
          return word.english.toLowerCase().contains(query) ||
                 word.turkish.toLowerCase().contains(query);
        }).toList();

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top Action Panel (Stats & PDF Export)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vocabulary Library',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.indigo[200] : Colors.indigo[900],
                            ),
                          ),
                          Text(
                            '${state.words.length} entries saved',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600], 
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _onExportPdf(context, state),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.indigo.withOpacity(0.12) : Colors.indigo[50],
                        foregroundColor: isDark ? Colors.indigo[200] : Colors.indigo[900],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isDark ? Colors.indigo.withOpacity(0.3) : Colors.indigo[100]!,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search words...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.indigo),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Word List
                Expanded(
                  child: filteredWords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.import_contacts, 
                                size: 48, 
                                color: isDark ? Colors.grey[800] : Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Your vocabulary library is empty'
                                    : 'No matching words found',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[500], 
                                  fontSize: 15,
                                ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddEditWordDialog(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Word'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.indigo[600] : Colors.indigo,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredWords.length,
                          itemBuilder: (context, index) {
                            final word = filteredWords[index];
                            final isPending = word.syncStatus == 'pending';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: isDark ? Colors.grey[900] : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark ? Colors.grey[800]! : (Colors.grey[150] ?? Colors.grey[200]!), 
                                  width: 0.8,
                                ),
                              ),
                              elevation: 0.5,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                          children: [
                                            TextSpan(text: word.english),
                                            if (word.phonetic.isNotEmpty) ...[
                                              const TextSpan(text: ' '),
                                              TextSpan(
                                                text: '(${word.phonetic})',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.normal,
                                                  color: isDark ? Colors.indigo[200] : Colors.indigo[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                            const TextSpan(text: ' = '),
                                            TextSpan(
                                              text: word.turkish,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.grey[300] : Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isPending)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.orange.withOpacity(0.12) : Colors.orange[50],
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark ? Colors.orange.withOpacity(0.3) : Colors.orange[200]!, 
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                              width: 10,
                                              height: 10,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Pending Sync',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined, 
                                        size: 20, 
                                        color: isDark ? Colors.grey[400] : Colors.blueGrey,
                                      ),
                                      onPressed: () => _showAddEditWordDialog(context, existingWord: word),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                      onPressed: () => state.deleteWord(word.id!),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
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
          ),
          floatingActionButton: state.words.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () => _showAddEditWordDialog(context),
                  backgroundColor: isDark ? Colors.indigo[600] : Colors.indigo,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                )
              : null,
      },
    );
  }
}
