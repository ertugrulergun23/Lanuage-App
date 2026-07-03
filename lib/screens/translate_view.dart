import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class TranslateView extends StatefulWidget {
  const TranslateView({Key? key}) : super(key: key);

  @override
  State<TranslateView> createState() => _TranslateViewState();
}

class _TranslateViewState extends State<TranslateView> {
  final TextEditingController _inputController = TextEditingController();
  bool _addedSuccessfully = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _onAddPressed(AppState state) async {
    if (state.translateOutput.isEmpty) return;

    await state.addTranslationToLibrary();
    _inputController.clear();
    
    setState(() {
      _addedSuccessfully = true;
    });

    // Reset indicator after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _addedSuccessfully = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final online = state.isOnline;
        final isDark = state.isDarkMode;

        // Synchronize controller text when state changes (e.g., on swap direction toggle)
        if (_inputController.text != state.translateInput) {
          _inputController.text = state.translateInput;
          // Set cursor to the end of the text
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Text(
                'Translate & Save',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.indigo[200] : Colors.indigo[900],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Translate words or full sentences, and add them instantly to your learning library.',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600], 
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Translation Box Card
              Card(
                elevation: isDark ? 1 : 4,
                shadowColor: Colors.black12,
                color: isDark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Translation Direction Selector (Two-way)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.language_rounded, 
                                  size: 18, 
                                  color: isDark ? Colors.indigo[200] : Colors.indigo[800],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.isEnglishToTurkish ? 'English' : 'Turkish',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.isEnglishToTurkish ? 'Turkish' : 'English',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(
                                    Icons.swap_horiz_rounded,
                                    color: isDark ? Colors.indigo[200] : Colors.indigo[800],
                                  ),
                                  onPressed: online ? () => state.toggleTranslationDirection() : null,
                                  tooltip: 'Swap Translation Direction',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ],
                            ),
                          ),

                          // Source Input
                          TextField(
                            controller: _inputController,
                            maxLines: 4,
                            enabled: online,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: state.isEnglishToTurkish 
                                  ? 'Enter English word or sentence here...'
                                  : 'Türkçe kelime veya cümle girin...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.grey[700]! : Colors.grey[250]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.indigo, width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(14),
                              fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                              filled: true,
                            ),
                            onChanged: (text) => state.setTranslateInput(text),
                          ),
                          const SizedBox(height: 16),

                          // Translate Action Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: (online && state.translateInput.trim().isNotEmpty)
                                    ? () => state.translate()
                                    : null,
                                icon: state.isTranslating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.translate, size: 18),
                                label: const Text('Translate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.indigo[600] : Colors.indigo[800],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),

                          // Output Box
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 100),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(isDark ? 0.12 : 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.indigo.withOpacity(isDark ? 0.3 : 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.isEnglishToTurkish 
                                      ? 'TURKISH TRANSLATION'
                                      : 'ENGLISH TRANSLATION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.indigo[200] : Colors.indigo[700],
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (state.translateOutput.isNotEmpty)
                                  SelectableText(
                                    state.translateOutput,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  )
                                else
                                  Text(
                                    'Translation will appear here...',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Add to Library Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: state.translateOutput.isNotEmpty
                                  ? () => _onAddPressed(state)
                                  : null,
                              icon: Icon(
                                _addedSuccessfully ? Icons.check_circle : Icons.bookmark_add,
                                color: Colors.white,
                              ),
                              label: Text(
                                _addedSuccessfully ? 'Added to Library!' : 'Add to Library',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _addedSuccessfully ? Colors.teal : (isDark ? Colors.indigo[600] : Colors.indigo[700]),
                                disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                disabledForegroundColor: isDark ? Colors.grey[600] : Colors.grey[400],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Glassmorphic Offline Overlay
                      if (!online)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.wifi_off, size: 48, color: Colors.orange[700]),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Translation Offline',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Active internet connection required for Translation. You can still access Library, Flashcards, and Writing!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
