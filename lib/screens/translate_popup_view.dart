import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/db_service.dart';
import '../models/word.dart';

// MethodChannel identifier — must match TranslatePopupActivity.CHANNEL
const _kChannel = 'com.example.language_app/process_text';

/// Entry point for the popup route ("/popup").
///
/// [PopupApp] is a minimal, self-contained Flutter app that wraps
/// [TranslatePopupView].  It does NOT use Provider or the main AppState —
/// services are called directly to keep the engine lightweight.
class PopupApp extends StatelessWidget {
  const PopupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
          primary: Colors.indigo[300]!,
        ),
      ),
      // Transparent scaffold so the translucent Activity shows through
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const TranslatePopupView(),
    );
  }
}

/// Floating translate card displayed over the calling app.
///
/// Behaviour:
///   • Receives the user's selected text via MethodChannel and pre-fills the
///     input field.
///   • Calls [ApiService.translate] directly (English → Turkish by default).
///   • Calls [DatabaseService.insertWord] to add the pair to the shared DB.
///   • Tapping outside the card or pressing Back calls [SystemNavigator.pop],
///     which finishes the Activity and returns to the calling app.
class TranslatePopupView extends StatefulWidget {
  const TranslatePopupView({super.key});

  @override
  State<TranslatePopupView> createState() => _TranslatePopupViewState();
}

class _TranslatePopupViewState extends State<TranslatePopupView>
    with SingleTickerProviderStateMixin {
  // ── Services ───────────────────────────────────────────────────────────────
  final _api = ApiService();
  final _db = DatabaseService.instance;

  // ── Channel ────────────────────────────────────────────────────────────────
  static const _channel = MethodChannel(_kChannel);

  // ── Local state ────────────────────────────────────────────────────────────
  final _inputController = TextEditingController();
  String _output = '';
  bool _isTranslating = false;
  bool _addedSuccessfully = false;
  bool _isEnglishToTurkish = true;

  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Card slide-up animation
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    // Register MethodChannel handler to receive selected text from native side
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'setSelectedText') {
      final text = (call.arguments as String?) ?? '';
      if (text.isNotEmpty) {
        setState(() {
          _inputController.text = text;
          _output = '';
          _addedSuccessfully = false;
        });
        // Auto-translate when text arrives from selection
        await _translate();
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _inputController.dispose();
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _translate() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _addedSuccessfully = false;
    });

    try {
      final result = await _api.translate(
        input,
        isEnglishToTurkish: _isEnglishToTurkish,
      );
      if (mounted) {
        setState(() => _output = result);
      }
    } catch (_) {
      if (mounted) setState(() => _output = '');
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _addToLibrary() async {
    final input = _inputController.text.trim();
    if (input.isEmpty || _output.isEmpty) return;

    final english = _isEnglishToTurkish ? input : _output;
    final turkish = _isEnglishToTurkish ? _output : input;

    // Fetch phonetic if possible (fire-and-forget; won't block the UI)
    String phonetic = '';
    try {
      phonetic = await _api.fetchPhonetic(english);
    } catch (_) {}

    final word = Word(
      english: english,
      turkish: turkish,
      phonetic: phonetic,
      syncStatus: 'synced',
    );

    await _db.insertWord(word);

    if (mounted) {
      setState(() => _addedSuccessfully = true);
      // Brief success indicator, then close
      await Future.delayed(const Duration(milliseconds: 1200));
      _closePopup();
    }
  }

  void _swapDirection() {
    setState(() {
      final tmp = _inputController.text;
      _inputController.text = _output;
      _output = tmp;
      _isEnglishToTurkish = !_isEnglishToTurkish;
    });
  }

  /// Animate out then finish the Activity, returning to the calling app.
  Future<void> _closePopup() async {
    await _animCtrl.reverse();
    SystemNavigator.pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Full-screen transparent scaffold — tapping the dim area closes the popup
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _closePopup,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: GestureDetector(
                  // Prevent taps inside the card from propagating to the dismiss handler
                  onTap: () {},
                  child: _buildCard(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildDivider(),
          _buildInputSection(),
          _buildTranslateButton(),
          _buildDivider(),
          _buildOutputSection(),
          if (_output.isNotEmpty) _buildAddToLibraryButton(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Card sections ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Row(
        children: [
          Icon(Icons.translate_rounded,
              size: 18, color: Colors.indigo[300]),
          const SizedBox(width: 8),
          Text(
            _isEnglishToTurkish ? 'English  →  Turkish' : 'Turkish  →  English',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[200],
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          // Swap direction button
          IconButton(
            icon: Icon(Icons.swap_horiz_rounded,
                size: 20, color: Colors.indigo[300]),
            onPressed: _swapDirection,
            tooltip: 'Swap direction',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          // Close button
          IconButton(
            icon: Icon(Icons.close_rounded,
                size: 20, color: Colors.grey[500]),
            onPressed: _closePopup,
            tooltip: 'Close',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _inputController,
        maxLines: 3,
        minLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: _isEnglishToTurkish
              ? 'English word or sentence…'
              : 'Türkçe kelime veya cümle…',
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.indigo.withOpacity(0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.indigo.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.indigo[400]!, width: 1.5),
          ),
          // Clear button
          suffixIcon: _inputController.text.isNotEmpty
              ? IconButton(
                  icon:
                      Icon(Icons.clear_rounded, size: 16, color: Colors.grey[600]),
                  onPressed: () => setState(() {
                    _inputController.clear();
                    _output = '';
                  }),
                )
              : null,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _translate(),
      ),
    );
  }

  Widget _buildTranslateButton() {
    final canTranslate =
        _inputController.text.trim().isNotEmpty && !_isTranslating;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canTranslate ? _translate : null,
          icon: _isTranslating
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.translate_rounded, size: 16),
          label: Text(
            _isTranslating ? 'Translating…' : 'Translate',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[700],
            disabledBackgroundColor: Colors.indigo.withOpacity(0.2),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutputSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEnglishToTurkish ? 'TURKISH TRANSLATION' : 'ENGLISH TRANSLATION',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[300],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            _output.isNotEmpty
                ? SelectableText(
                    _output,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  )
                : Text(
                    'Translation will appear here…',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToLibraryButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _addedSuccessfully ? null : _addToLibrary,
          icon: Icon(
            _addedSuccessfully ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
            size: 16,
          ),
          label: Text(
            _addedSuccessfully ? 'Added to Library!' : 'Add to Library',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _addedSuccessfully ? Colors.teal[700] : Colors.indigo[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.white.withOpacity(0.07),
      );
}
