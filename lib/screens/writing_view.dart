import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class WritingView extends StatefulWidget {
  const WritingView({Key? key}) : super(key: key);

  @override
  State<WritingView> createState() => _WritingViewState();
}

class _WritingViewState extends State<WritingView> {
  final TextEditingController _countController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    _countController.text = state.writingWordCount.toString();
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _increment(AppState state) {
    int current = int.tryParse(_countController.text) ?? state.writingWordCount;
    current++;
    _countController.text = current.toString();
    state.setWritingWordCount(current);
  }

  void _decrement(AppState state) {
    int current = int.tryParse(_countController.text) ?? state.writingWordCount;
    if (current > 1) {
      current--;
      _countController.text = current.toString();
      state.setWritingWordCount(current);
    }
  }

  void _onCountChanged(String val, AppState state) {
    int? parsed = int.tryParse(val);
    if (parsed != null && parsed >= 1) {
      state.setWritingWordCount(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        // Sync text controller in case the value was set externally
        if (int.tryParse(_countController.text) != state.writingWordCount) {
          _countController.text = state.writingWordCount.toString();
        }

        final libraryEmpty = state.words.isEmpty;
        final hasPrompt = state.currentWritingTopic != null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Writing Practice',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Write a paragraph containing the words below.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),

                  // Refresh Topics Button
                  IconButton.filledTonal(
                    onPressed: state.isOnline && !state.isLoadingTopics
                        ? () async {
                            await state.refreshTopicsOnline();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Topics refreshed and cached from online feed!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : null,
                    icon: state.isLoadingTopics
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded, size: 20),
                    tooltip: 'Refresh Online Topics',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.indigo[50],
                      foregroundColor: Colors.indigo[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Empty Library Fallback Warning
              if (libraryEmpty)
                Card(
                  color: Colors.amber[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber[250] ?? Colors.amber, width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber[900], size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your vocabulary library is empty. Please add words in the Translate or Library screen first to enable writing prompts!',
                            style: TextStyle(color: Colors.amber[900], fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // The Topic Display Card
              Card(
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.indigo[900]!, Colors.indigo[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              hasPrompt ? state.currentWritingTopic!.category.toUpperCase() : 'GET STARTED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          if (!state.isOnline)
                            Row(
                              children: [
                                const Icon(Icons.cloud_off, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  'Cached Mode',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hasPrompt 
                            ? '"${state.currentWritingTopic!.name}"' 
                            : 'Click "Generate New" below to get a writing topic and pick vocabulary words.',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Instructions: Grab a pen & paper (or open your notes app) and write a short entry addressing the topic above. You must incorporate all vocabulary words shown below.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Controls Panel
              Text(
                'Vocabulary Config',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo[900], letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text(
                        'Word Count (N):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),

                      // Decrement Button
                      IconButton(
                        onPressed: !libraryEmpty ? () => _decrement(state) : null,
                        icon: const Icon(Icons.remove),
                        color: Colors.indigo,
                      ),

                      // Direct Input Field
                      SizedBox(
                        width: 50,
                        height: 36,
                        child: TextField(
                          controller: _countController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          enabled: !libraryEmpty,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) => _onCountChanged(val, state),
                        ),
                      ),

                      // Increment Button
                      IconButton(
                        onPressed: !libraryEmpty ? () => _increment(state) : null,
                        icon: const Icon(Icons.add),
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Words Display Panel
              if (hasPrompt) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INCORPORATE THESE WORDS (${state.selectedWritingWords.length}):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo[700], letterSpacing: 1.0),
                    ),
                    if (state.selectedWritingWords.length < state.writingWordCount && !libraryEmpty)
                      Text(
                        'Library cap reached',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.selectedWritingWords.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'No words selected. Try updating or adding words to library.',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: state.selectedWritingWords.map((word) {
                      return Chip(
                        label: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(text: word.english),
                              if (word.phonetic.isNotEmpty) ...[
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: word.phonetic,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.indigo[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        backgroundColor: Colors.indigo.withOpacity(0.06),
                        side: BorderSide(color: Colors.indigo.withOpacity(0.15)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 28),
              ],

              // Main Buttons Panel
              Row(
                children: [
                  // Generate New Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !libraryEmpty
                          ? () => state.generateNewWritingPrompt()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Generate New',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Update Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (!libraryEmpty && hasPrompt)
                          ? () => state.updateWritingWordsOnly()
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo[800],
                        side: BorderSide(color: Colors.indigo[800]!, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Update Words',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
