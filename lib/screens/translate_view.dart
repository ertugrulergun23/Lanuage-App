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
                  color: Colors.indigo[900],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Translate words or full sentences, and add them instantly to your learning library.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Translation Box Card
              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Source Input (English)
                          TextField(
                            controller: _inputController,
                            maxLines: 4,
                            enabled: online,
                            decoration: InputDecoration(
                              hintText: 'Enter English word or sentence here...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.indigo, width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(14),
                              fillColor: Colors.grey[50],
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
                                  backgroundColor: Colors.indigo[800],
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

                          // Output Box (Turkish)
                          Container(
                            width: double.infinity,
                            minHeight: 100,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TURKISH TRANSLATION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo[700],
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (state.translateOutput.isNotEmpty)
                                  SelectableText(
                                    state.translateOutput,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
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
                                backgroundColor: _addedSuccessfully ? Colors.teal : Colors.indigo[700],
                                disabledBackgroundColor: Colors.grey[200],
                                disabledForegroundColor: Colors.grey[400],
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
                              color: Colors.white.withOpacity(0.85),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.wifi_off, size: 48, color: Colors.orange[700]),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Translation Offline',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Active internet connection required for Translation. You can still access Library, Flashcards, and Writing!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
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
