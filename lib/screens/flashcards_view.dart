import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/flip_card.dart';
import '../models/word.dart';

class FlashcardsView extends StatefulWidget {
  const FlashcardsView({Key? key}) : super(key: key);

  @override
  State<FlashcardsView> createState() => _FlashcardsViewState();
}

class _FlashcardsViewState extends State<FlashcardsView> {
  int _currentIndex = 0;

  void _nextCard(int totalCards) {
    if (_currentIndex < totalCards - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final cards = state.flashcardWords;
        final isDark = state.isDarkMode;

        if (cards.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.style_outlined, 
                    size: 64, 
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Flashcards Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.indigo[200] : Colors.indigo[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add words or phrases to your library, and they will automatically populate as practice flashcards here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey, 
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Bound check index in case words are deleted in library
        if (_currentIndex >= cards.length) {
          _currentIndex = cards.length - 1;
        }
        if (_currentIndex < 0) {
          _currentIndex = 0;
        }

        final word = cards[_currentIndex];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Header
              Column(
                children: [
                  Text(
                    'Practice Flashcards',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.indigo[200] : Colors.indigo[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the card to flip and reveal the translation',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600], 
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Card Counter / Progress
              Text(
                'CARD ${_currentIndex + 1} OF ${cards.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.indigo[200] : Colors.indigo[400],
                ),
              ),
              const SizedBox(height: 16),

              // The 3D Flip Card Widget
              // Unique key forces recreation of FlipCard state on card index change
              FlipCard(
                key: ValueKey(word.id),
                front: _buildCardSide(
                  context: context,
                  title: 'English Phrase',
                  content: word.english,
                  subtitle: word.phonetic.isNotEmpty ? word.phonetic : 'No phonetic available',
                  gradient: LinearGradient(
                    colors: [Colors.indigo[800]!, Colors.indigo[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  textColor: Colors.white,
                  subTextColor: Colors.indigo[100]!,
                ),
                back: _buildCardSide(
                  context: context,
                  title: 'Turkish Translation',
                  content: word.turkish,
                  subtitle: 'Tap to flip back',
                  gradient: LinearGradient(
                    colors: [Colors.teal[700]!, Colors.teal[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  textColor: Colors.white,
                  subTextColor: Colors.teal[100]!,
                ),
              ),
              
              const Spacer(),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous Card Button
                  IconButton.filledTonal(
                    onPressed: _currentIndex > 0 ? _prevCard : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: isDark ? Colors.grey[850] : null,
                      disabledBackgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
                      disabledForegroundColor: Colors.grey[600],
                    ),
                  ),
                  
                  // Quick Hint text
                  Row(
                    children: [
                      Icon(
                        Icons.flip_camera_android_rounded, 
                        size: 16, 
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to Flip',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),

                  // Next Card Button
                  IconButton.filledTonal(
                    onPressed: _currentIndex < cards.length - 1 
                        ? () => _nextCard(cards.length) 
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: isDark ? Colors.grey[850] : null,
                      disabledBackgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
                      disabledForegroundColor: Colors.grey[600],
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

  Widget _buildCardSide({
    required BuildContext context,
    required String title,
    required String content,
    required String subtitle,
    required Gradient gradient,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Small Top Label
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: subTextColor,
            ),
          ),
          const Spacer(),
          
          // Main content
          Center(
            child: Column(
              children: [
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: subTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const Spacer(),
          // Visual cue at the bottom
          Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.touch_app_outlined,
              color: subTextColor.withOpacity(0.5),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
