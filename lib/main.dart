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
        fontFamily: 'monospace',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'monospace',
            color: textPrimary,
            fontSize: 14,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'monospace',
            color: textMuted,
            fontSize: 12,
            height: 1.5,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();

    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _cursorController.addListener(() {
      if (mounted) {
        setState(() {
          _showCursor = _cursorController.value > 0.5;
        });
      }
    });

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _addWelcomeMessage() {
    _messages.add(TerminalMessage(
      type: MessageType.system,
      content: 'Welcome to Termux Agent v1.0.0\nType "help" for available commands.',
      timestamp: DateTime.now(),
    ));
    _messages.add(TerminalMessage(
      type: MessageType.assistant,
      content: 'Halo! Saya Termux Agent, asisten AI untuk Termux.\n\nKetik pertanyaan atau perintah di bawah.\nContoh: "list files", "check storage", "run script"',
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
        'Command executed successfully.\nOutput: [simulated result]',
        'Processing request... Done.\nResult: OK',
        'I understand. In terminal mode, I can help with:\n  • File operations\n  • Package management\n  • System info\n  • Script execution',
        'Unknown command. Type "help" for usage.',
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

    final sessionDuration = DateTime.now().difference(_sessionStart);

    return Scaffold(
      backgroundColor: bgPrimary,
      body: Column(
        children: [
          // ─── TOP BANNER ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: bgSecondary,
              border: Border(
                bottom: BorderSide(color: accentCyan.withOpacity(0.5), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '⚡ ',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: accentCyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Termux Agent',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: accentCyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentGreen.withOpacity(0.15),
                        border: Border.all(color: accentGreen, width: 1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Text(
                        ' BUILD ',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: accentGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Model: gpt-oss-120b',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgPrimary,
                    border: Border(
                      left: BorderSide(color: accentYellow, width: 3),
                    ),
                  ),
                  child: const Text(
                    'TIP: Type "help" for commands | "clear" to reset | Ctrl+C to interrupt',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: accentYellow,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── CHAT AREA ───
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: bgSecondary,
              border: Border(
                top: BorderSide(color: Color(0xFF30363D), width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
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
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFC9D1D9),
                      fontSize: 14,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendCommand(),
                    decoration: const InputDecoration(
                      hintText: 'Enter command...',
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Color(0xFF58A6FF), size: 22),
                  onPressed: _isLoading ? null : _sendCommand,
                  tooltip: 'Send',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),

          // ─── BOTTOM STATUS BAR ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: bgSecondary,
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
                const SizedBox(width: 24),
                Text(
                  'Tokens: ~${_tokenCount}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF8B949E),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  'Mode: BUILD',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF3FB950),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Termux Agent v1.0.0',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF484F58),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalMessage(TerminalMessage msg) {
    const Color bgPrimary = Color(0xFF0D1117);
    const Color bgSecondary = Color(0xFF161B22);
    const Color textPrimary = Color(0xFFC9D1D9);
    const Color accentCyan = Color(0xFF58A6FF);
    const Color accentBlue = Color(0xFF58A6FF);
    const Color accentGreen = Color(0xFF3FB950);

    switch (msg.type) {
      case MessageType.user:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SelectableText.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'USER > ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: accentBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: msg.content,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: textPrimary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );

      case MessageType.assistant:
        return Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgSecondary,
            border: Border(
              left: BorderSide(color: accentCyan, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🤖 ASSISTANT',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: accentCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                msg.content,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: textPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );

      case MessageType.system:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgSecondary,
              border: Border.all(color: Color(0xFF30363D), width: 1),
            ),
            child: SelectableText(
              msg.content,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF8B949E),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        );

      case MessageType.error:
        return Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgSecondary,
            border: Border(
              left: BorderSide(color: const Color(0xFFF85149), width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✖ ERROR',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFF85149),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                msg.content,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFC9D1D9),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          left: BorderSide(color: const Color(0xFF58A6FF), width: 2),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '🤖 ASSISTANT ',
            style: TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF58A6FF),
              fontSize: 11,
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