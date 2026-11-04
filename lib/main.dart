import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const TermuxAgentApp());
}

class TermuxAgentApp extends StatelessWidget {
  const TermuxAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgPrimary = Color(0xFF0D1117);
    const Color bgSecondary = Color(0xFF161B22);
    const Color textPrimary = Color(0xFFC9D1D9);
    const Color textMuted = Color(0xFF8B949E);
    const Color accentCyan = Color(0xFF58A6FF);
    const Color accentGreen = Color(0xFF3FB950);
    const Color accentYellow = Color(0xFFD29922);
    const Color accentRed = Color(0xFFF85149);

    return MaterialApp(
      title: 'Termux Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgPrimary,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'monospace',
            color: textPrimary,
            fontSize: 14,
            height: 1.25,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'monospace',
            color: textMuted,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: accentCyan,
          secondary: accentGreen,
          surface: bgSecondary,
          background: bgPrimary,
          onSurface: textPrimary,
          onBackground: textPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: Color(0xFF30363D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: Color(0xFF30363D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: accentCyan, width: 1),
          ),
          filled: true,
          fillColor: bgSecondary,
          hintStyle: const TextStyle(
            fontFamily: 'monospace',
            color: textMuted,
            fontSize: 13,
            height: 1.25,
          ),
        ),
      ),
      home: const TerminalHomePage(),
    );
  }
}

class TerminalHomePage extends StatefulWidget {
  const TerminalHomePage({super.key});

  @override
  State<TerminalHomePage> createState() => _TerminalHomePageState();
}

class _TerminalHomePageState extends State<TerminalHomePage> with SingleTickerProviderStateMixin {
  final List<TerminalMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  late Timer _sessionTimer;
  DateTime _sessionStart = DateTime.now();
  int _tokenCount = 0;
  late AnimationController _cursorController;

  // FIX: Font size control for chat messages only
  double _chatFontSize = 11.0; // Default reduced from 14 to 11
  static const double _minFontSize = 8.0;
  static const double _maxFontSize = 24.0;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();

    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _addWelcomeMessage() {
    _messages.add(TerminalMessage(
      type: MessageType.assistant,
      content: 'Halo! Saya Termux Agent.\n\nKetik pertanyaan atau perintah di bawah.\nContoh: "list file", "cek storage", "jalankan script"',
      timestamp: DateTime.now(),
    ));
  }

  void _sendCommand() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(TerminalMessage(
        type: MessageType.user,
        content: text,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _tokenCount += text.length ~/ 4;
    });

    _controller.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final responses = [
        'Perintah dieksekusi dengan sukses.\nOutput: [simulasi hasil]',
        'Memproses permintaan... Selesai.\nHasil: OK',
        'Saya mengerti. Di mode terminal, saya bisa bantu:\n  • Operasi file\n  • Manajemen paket\n        • Info sistem\n  • Eksekusi script',
        'Perintah tidak dikenal. Ketik "help" untuk bantuan.',
      ];
      final response = responses[_messages.length % responses.length];

      setState(() {
        _messages.add(TerminalMessage(
          type: MessageType.assistant,
          content: response,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
        _tokenCount += response.length ~/ 4;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // FIX: Font size adjustment methods
  void _decreaseFontSize() {
    setState(() {
      if (_chatFontSize > _minFontSize) {
        _chatFontSize -= 1.0;
      }
    });
  }

  void _increaseFontSize() {
    setState(() {
      if (_chatFontSize < _maxFontSize) {
        _chatFontSize += 1.0;
      }
    });
  }

  void _resetFontSize() {
    setState(() {
      _chatFontSize = 11.0;
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sessionTimer.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgPrimary = Color(0xFF0D1117);
    const Color bgSecondary = Color(0xFF161B22);
    const Color textPrimary = Color(0xFFC9D1D9);
    const Color textMuted = Color(0xFF8B949E);
    const Color accentCyan = Color(0xFF58A6FF);
    const Color accentGreen = Color(0xFF3FB950);
    const Color accentYellow = Color(0xFFD29922);
    const Color accentRed = Color(0xFFF85149);

    final sessionDuration = DateTime.now().difference(_sessionStart);

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // ─── COMPACT HEADER with Font Size Controls ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: bgSecondary,
                border: Border(
                  bottom: BorderSide(color: accentCyan.withOpacity(0.4), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with font controls
                  Row(
                    children: [
                      const Text(
                        '⚡ Termux Agent',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF58A6FF),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // FIX: Font size controls (A- / A+)
                      _buildFontSizeButton(
                        label: 'A-',
                        onPressed: _decreaseFontSize,
                        tooltip: 'Perkecil font (${_chatFontSize.toInt()})',
                      ),
                      const SizedBox(width: 4),
                      _buildFontSizeButton(
                        label: 'A+',
                        onPressed: _increaseFontSize,
                        tooltip: 'Perbesar font (${_chatFontSize.toInt()})',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Model: gpt-oss-120b',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Badge + Tips row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.12),
                          border: Border.all(color: accentGreen, width: 1),
                        ),
                        child: const Text(
                          'BUILD',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF3FB950),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: bgPrimary,
                            border: Border(
                              left: BorderSide(color: accentYellow, width: 2),
                            ),
                          ),
                          child: const Text(
                            'TIP: Ketik "help" | "clear" reset | A-/A+ zoom font',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFFD29922),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── CHAT AREA ───
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildTerminalMessage(_messages[index]);
                },
              ),
            ),

            // ─── INPUT AREA ───
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: bgSecondary,
                border: Border(
                  top: BorderSide(color: Color(0xFF30363D), width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'USER > ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF58A6FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFFC9D1D9),
                        fontSize: 14,
                        height: 1.25,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendCommand(),
                      decoration: const InputDecoration(
                        hintText: 'Enter command...',
                        isCollapsed: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Color(0xFF58A6FF), size: 20),
                      onPressed: _isLoading ? null : _sendCommand,
                      tooltip: 'Kirim',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),

            // ─── FOOTER STATUS BAR ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              decoration: BoxDecoration(
                color: bgSecondary,
                border: Border(
                  top: BorderSide(color: Color(0xFF30363D), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: true,
                minimum: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      'Session: ${_formatDuration(sessionDuration)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF8B949E),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Tokens: ~${_tokenCount}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF8B949E),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Mode: BUILD',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF3FB950),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'v1.0.0',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF484F58),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIX: Helper widget for font size buttons
  Widget _buildFontSizeButton({
    required String label,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    const Color accentCyan = Color(0xFF58A6FF);
    const Color bgSecondary = Color(0xFF161B22);
    const Color textMuted = Color(0xFF8B949E);

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 28,
        height: 28,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: bgSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: accentCyan.withOpacity(0.5), width: 1),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: accentCyan,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  // FIX: Chat messages now use _chatFontSize variable
  Widget _buildTerminalMessage(TerminalMessage msg) {
    const Color bgPrimary = Color(0xFF0D1117);
    const Color bgSecondary = Color(0xFF161B22);
    const Color textPrimary = Color(0xFFC9D1D9);
    const Color accentCyan = Color(0xFF58A6FF);
    const Color accentBlue = Color(0xFF58A6FF);
    const Color accentGreen = Color(0xFF3FB950);
    const Color accentRed = Color(0xFFF85149);

    // FIX: TextStyle factory using _chatFontSize
    final chatStyle = TextStyle(
      fontFamily: 'monospace',
      color: textPrimary,
      fontSize: _chatFontSize,
      height: 1.25,
    );

    final labelStyle = TextStyle(
      fontFamily: 'monospace',
      color: accentCyan,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      height: 1.2,
    );

    switch (msg.type) {
      case MessageType.user:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'USER > ',
                  style: chatStyle.copyWith(
                    color: accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: msg.content,
                  style: chatStyle,
                ),
              ],
            ),
          ),
        );

      case MessageType.assistant:
        return Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: BoxDecoration(
            color: bgSecondary,
            border: Border(
              left: BorderSide(color: accentCyan, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🤖 ASSISTANT',
                style: labelStyle,
              ),
              const SizedBox(height: 3),
              SelectableText(
                msg.content,
                style: chatStyle,
              ),
            ],
          ),
        );

      case MessageType.system:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgSecondary,
              border: Border.all(color: Color(0xFF30363D), width: 1),
            ),
            child: SelectableText(
              msg.content,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF8B949E),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        );

      case MessageType.error:
        return Container(
          margin: const EdgeInsets.only(top: 6, bottom: 2),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: BoxDecoration(
            color: bgSecondary,
            border: Border(
              left: BorderSide(color: accentRed, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✖ ERROR',
                style: labelStyle.copyWith(color: accentRed),
              ),
              const SizedBox(height: 3),
              SelectableText(
                msg.content,
                style: chatStyle,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTypingIndicator() {
    const Color accentCyan = Color(0xFF58A6FF);

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          left: BorderSide(color: accentCyan, width: 2),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '🤖 ASSISTANT ',
            style: TextStyle(
              fontFamily: 'monospace',
              color: accentCyan,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          AnimatedBuilder(
            animation: _cursorController,
            builder: (_, __) {
              return Row(
                children: [
                  _buildDot(0),
                  _buildDot(1),
                  _buildDot(2),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 150;
    final animValue = (_cursorController.value * 1000 + delay) % 1000 / 1000;
    final opacity = (animValue < 0.5) ? 0.3 + animValue * 1.4 : 1.0 - (animValue - 0.5) * 1.4;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity.clamp(0.3, 1.0),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          '●',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFF58A6FF),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

enum MessageType { user, assistant, system, error }

class TerminalMessage {
  final MessageType type;
  final String content;
  final DateTime timestamp;

  TerminalMessage({
    required this.type,
    required this.content,
    required this.timestamp,
  });
}