import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'models/provider.dart';
import 'models/provider_data.dart';
import 'screens/provider_screen.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
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
        dialogTheme: DialogThemeData(
          backgroundColor: bgSecondary,
          shape: Border.all(color: accentCyan.withOpacity(0.5), width: 1),
          titleTextStyle: const TextStyle(
            fontFamily: 'monospace',
            color: accentCyan,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(
            fontFamily: 'monospace',
            color: textPrimary,
            fontSize: 13,
          ),
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

  // Font size control
  double _chatFontSize = 11.0;
  static const double _minFontSize = 8.0;
  static const double _maxFontSize = 24.0;

  // Provider management
  String _activeProviderId = 'nvidia_nim';
  String _activeModel = '';
  Provider _activeProvider = allProviders.firstWhere((p) => p.id == 'nvidia_nim');

  // Slash command autocomplete
  final LayerLink _inputLayerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _overlayFocusNode = FocusNode();
  String _currentCommandQuery = '';
  int _selectedCommandIndex = 0;
  bool _showAutocomplete = false;

  // Commands
  final List<SlashCommand> _commands = [
    SlashCommand('/help', 'Tampilkan bantuan'),
    SlashCommand('/clear', 'Bersihkan riwayat chat'),
    SlashCommand('/model', 'Ganti model AI'),
    SlashCommand('/stats', 'Statistik sesi'),
    SlashCommand('/exit', 'Keluar aplikasi'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _addWelcomeMessage();

    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  Future<void> _loadSettings() async {
    final fontSize = await StorageService.getChatFontSize(defaultSize: 11.0);
    final providerId = StorageService.getActiveProvider(defaultId: 'nvidia_nim');
    final provider = getProviderById(providerId) ?? allProviders.firstWhere((p) => p.id == 'nvidia_nim');
    final model = StorageService.getActiveModel(providerId, defaultModel: provider.defaultModel);

    setState(() {
      _chatFontSize = fontSize;
      _activeProviderId = providerId;
      _activeProvider = provider;
      _activeModel = model;
    });
  }

  void _addWelcomeMessage() {
    _messages.add(TerminalMessage(
      type: MessageType.assistant,
      content: 'Halo! Saya Termux Agent.\n\nKetik pertanyaan atau perintah di bawah.\nContoh: "list file", "cek storage", "jalankan script"\n\nKetik "/" untuk melihat perintah slash yang tersedia.',
      timestamp: DateTime.now(),
    ));
  }

  void _onTextChanged() {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    if (cursorPos > 0 && text.isNotEmpty) {
      int slashIndex = -1;
      for (int i = cursorPos - 1; i >= 0; i--) {
        if (text[i] == ' ') break;
        if (text[i] == '/') {
          slashIndex = i;
          break;
        }
      }

      if (slashIndex != -1) {
        final query = text.substring(slashIndex + 1, cursorPos);
        _showAutocompleteForQuery(query, slashIndex);
      } else {
        _hideAutocomplete();
      }
    } else {
      _hideAutocomplete();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 100), _hideAutocomplete);
    }
  }

  void _showAutocompleteForQuery(String query, int slashIndex) {
    _currentCommandQuery = query.toLowerCase();
    _selectedCommandIndex = 0;

    final filtered = _commands.where((cmd) {
      return cmd.name.toLowerCase().startsWith('/$_currentCommandQuery');
    }).toList();

    if (filtered.isEmpty) {
      _hideAutocomplete();
      return;
    }

    if (!_showAutocomplete) {
      _showAutocomplete = true;
      _overlayEntry = _createOverlayEntry(slashIndex);
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _hideAutocomplete() {
    if (_showAutocomplete) {
      _showAutocomplete = false;
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry(int slashIndex) {
    return OverlayEntry(
      builder: (context) => _AutocompleteOverlay(
        layerLink: _inputLayerLink,
        commands: _commands.where((cmd) {
          return cmd.name.toLowerCase().startsWith('/$_currentCommandQuery');
        }).toList(),
        selectedIndex: _selectedCommandIndex,
        onSelect: (command) => _selectCommand(command, slashIndex),
        onIndexChange: (index) => setState(() => _selectedCommandIndex = index),
      ),
    );
  }

  void _selectCommand(SlashCommand command, int slashIndex) {
    final text = _controller.text;
    final newText = text.substring(0, slashIndex) + command.name + ' ';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _hideAutocomplete();
    _focusNode.requestFocus();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!_showAutocomplete) return;

    final filtered = _commands.where((cmd) {
      return cmd.name.toLowerCase().startsWith('/$_currentCommandQuery');
    }).toList();

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedCommandIndex = (_selectedCommandIndex + 1) % filtered.length;
      });
      _overlayEntry?.markNeedsBuild();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedCommandIndex = (_selectedCommandIndex - 1 + filtered.length) % filtered.length;
      });
      _overlayEntry?.markNeedsBuild();
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
               event.logicalKey == LogicalKeyboardKey.tab) {
      if (filtered.isNotEmpty) {
        _selectCommand(filtered[_selectedCommandIndex], 0);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _hideAutocomplete();
    }
  }

  void _sendCommand() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (text.startsWith('/')) {
      _executeSlashCommand(text);
      _controller.clear();
      return;
    }

    _sendToAPI(text);
    _controller.clear();
  }

  Future<void> _sendToAPI(String text) async {
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

    try {
      // Build message history
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': 'You are Termux Agent, a helpful terminal-based AI assistant. Respond in Indonesian.'},
      ];
      
      // Add recent messages (last 10)
      final recentMessages = _messages.toList().reversed.take(10).toList().reversed;
      for (final msg in recentMessages) {
        if (msg.type == MessageType.user) {
          messages.add({'role': 'user', 'content': msg.content});
        } else if (msg.type == MessageType.assistant) {
          messages.add({'role': 'assistant', 'content': msg.content});
        }
      }

      final response = await ApiService.sendMessage(
        provider: _activeProvider,
        apiKey: StorageService.getApiKey(_activeProviderId) ?? '',
        model: _activeModel,
        messages: messages,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(TerminalMessage(
          type: MessageType.assistant,
          content: response,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
        _tokenCount += response.length ~/ 4;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(TerminalMessage(
          type: MessageType.error,
          content: e.toString().replaceFirst('Exception: ', ''),
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _executeSlashCommand(String command) {
    final parts = command.split(' ');
    final cmd = parts[0].toLowerCase();

    switch (cmd) {
      case '/help':
        _messages.add(TerminalMessage(
          type: MessageType.system,
          content: 'Daftar Perintah Slash:\n' +
              _commands.map((c) => '${c.name.padRight(10)} - ${c.description}').join('\n'),
          timestamp: DateTime.now(),
        ));
        break;

      case '/clear':
        setState(() {
          _messages.clear();
          _addWelcomeMessage();
        });
        break;

      case '/model':
        _showModelDialog();
        break;

      case '/stats':
        final duration = DateTime.now().difference(_sessionStart);
        final h = duration.inHours.toString().padLeft(2, '0');
        final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
        _messages.add(TerminalMessage(
          type: MessageType.system,
          content: 'Statistik Sesi:\n  Session: $h:$m:$s\n  Tokens: ~${_tokenCount}\n  Mode: BUILD\n  Model: $_activeModel\n  Provider: ${_activeProvider.name}',
          timestamp: DateTime.now(),
        ));
        break;

      case '/exit':
        SystemNavigator.pop();
        break;

      default:
        _messages.add(TerminalMessage(
          type: MessageType.error,
          content: 'Perintah tidak dikenal: $cmd\nKetik /help untuk daftar perintah.',
          timestamp: DateTime.now(),
        ));
    }
    _scrollToBottom();
  }

  void _showModelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: Border.all(color: const Color(0xFF58A6FF).withOpacity(0.5), width: 1),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: const Text(
          'Pilih Model',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFF58A6FF),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _activeProvider.models.length,
            separatorBuilder: (_, __) => const Divider(
              color: Color(0xFF30363D),
              height: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
            ),
            itemBuilder: (context, index) {
              final model = _activeProvider.models[index];
              final isSelected = model == _activeModel;
              return InkWell(
                onTap: () async {
                  await StorageService.setActiveModel(_activeProviderId, model);
                  setState(() => _activeModel = model);
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? const Color(0xFF58A6FF) : const Color(0xFF8B949E),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          model,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: isSelected ? const Color(0xFF58A6FF) : const Color(0xFFC9D1D9),
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF8B949E),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: Border.all(color: const Color(0xFF58A6FF).withOpacity(0.5), width: 1),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text(
            'Pengaturan',
            style: TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF58A6FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Font Size Section
              const Text(
                'Ukuran Font Chat',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF58A6FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'A-',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: _chatFontSize <= _minFontSize ? const Color(0xFF8B949E) : const Color(0xFF58A6FF),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        activeTrackColor: const Color(0xFF58A6FF),
                        inactiveTrackColor: const Color(0xFF30363D),
                        thumbColor: const Color(0xFF58A6FF),
                        overlayColor: const Color(0xFF58A6FF).withOpacity(0.2),
                        valueIndicatorColor: const Color(0xFF58A6FF),
                        valueIndicatorTextStyle: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF0D1117),
                          fontSize: 11,
                        ),
                      ),
                      child: Slider(
                        value: _chatFontSize,
                        min: _minFontSize,
                        max: _maxFontSize,
                        divisions: ((_maxFontSize - _minFontSize)).toInt(),
                        label: _chatFontSize.toInt().toString(),
                        onChanged: (value) {
                          setDialogState(() => _chatFontSize = value);
                          setState(() => _chatFontSize = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'A+',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: _chatFontSize >= _maxFontSize ? const Color(0xFF8B949E) : const Color(0xFF58A6FF),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  'Ukuran: ${_chatFontSize.toInt()}sp',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF8B949E),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF30363D), height: 1),
              const SizedBox(height: 16),

              // Active Provider Section
              const Text(
                'Provider Aktif',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF58A6FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  border: Border.all(color: const Color(0xFF30363D)),
                  borderRadius: BorderRadius.zero,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _activeProviderId,
                    dropdownColor: const Color(0xFF161B22),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFC9D1D9),
                      fontSize: 13,
                    ),
                    items: allProviders.map((provider) {
                      return DropdownMenuItem(
                        value: provider.id,
                        child: Text(
                          '${provider.name} (${provider.category.label})',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFFC9D1D9),
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        final provider = getProviderById(value)!;
                        await StorageService.setActiveProvider(value);
                        final model = StorageService.getActiveModel(value, defaultModel: provider.defaultModel);
                        setDialogState(() {
                          _activeProviderId = value;
                          _activeProvider = provider;
                          _activeModel = model;
                        });
                        setState(() {
                          _activeProviderId = value;
                          _activeProvider = provider;
                          _activeModel = model;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Model Selection
              const Text(
                'Model Default',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF58A6FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  border: Border.all(color: const Color(0xFF30363D)),
                  borderRadius: BorderRadius.zero,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _activeModel,
                    dropdownColor: const Color(0xFF161B22),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFC9D1D9),
                      fontSize: 13,
                    ),
                    items: _activeProvider.models.map((model) {
                      return DropdownMenuItem(
                        value: model,
                        child: Text(
                          model,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFFC9D1D9),
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        await StorageService.setActiveModel(_activeProviderId, value);
                        setDialogState(() => _activeModel = value);
                        setState(() => _activeModel = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF30363D), height: 1),
              const SizedBox(height: 16),

              // Provider Management Button
              const Text(
                'Kelola Provider',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF58A6FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.grid_view, size: 18, color: Color(0xFF58A6FF)),
                  label: const Text(
                    'Buka Kelola Provider',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF58A6FF),
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: const Color(0xFF58A6FF).withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderScreen(
                          activeProviderId: _activeProviderId,
                          onProviderSelected: (id) async {
                            final provider = getProviderById(id)!;
                            await StorageService.setActiveProvider(id);
                            final model = StorageService.getActiveModel(id, defaultModel: provider.defaultModel);
                            setState(() {
                              _activeProviderId = id;
                              _activeProvider = provider;
                              _activeModel = model;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF8B949E),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProviderScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderScreen(
          activeProviderId: _activeProviderId,
          onProviderSelected: (id) async {
            final provider = getProviderById(id)!;
            await StorageService.setActiveProvider(id);
            final model = StorageService.getActiveModel(id, defaultModel: provider.defaultModel);
            setState(() {
              _activeProviderId = id;
              _activeProvider = provider;
              _activeModel = model;
            });
          },
        ),
      ),
    );
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
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _overlayFocusNode.dispose();
    _hideAutocomplete();
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
        child: KeyboardListener(
          focusNode: _overlayFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: Column(
            children: [
              // ─── CLEAN HEADER ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: bgSecondary,
                  border: Border(
                    bottom: BorderSide(color: accentCyan.withOpacity(0.4), width: 1),
                  ),
                ),
                child: Row(
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
                    // Settings icon
                    Tooltip(
                      message: 'Pengaturan',
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Color(0xFF58A6FF), size: 20),
                          onPressed: _showSettingsDialog,
                          tooltip: 'Pengaturan',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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

              // ─── INPUT AREA (Compact) ───
              CompositedTransformTarget(
                link: _inputLayerLink,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 44),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFFC9D1D9),
                              fontSize: 14,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendCommand(),
                            decoration: const InputDecoration(
                              hintText: 'Ketik pesan atau perintah...',
                              isCollapsed: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                            ),
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
              ),

              // ─── MODEL INFO (below input) ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                color: bgSecondary,
                child: Row(
                  children: [
                    const Text(
                      'Model: ',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF8B949E),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _activeModel,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF58A6FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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
    const Color accentRed = Color(0xFFF85149);

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
              style: TextStyle(
                fontFamily: 'monospace',
                color: const Color(0xFF8B949E),
                fontSize: _chatFontSize,
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

class _AutocompleteOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final List<SlashCommand> commands;
  final int selectedIndex;
  final Function(SlashCommand) onSelect;
  final Function(int) onIndexChange;

  const _AutocompleteOverlay({
    required this.layerLink,
    required this.commands,
    required this.selectedIndex,
    required this.onSelect,
    required this.onIndexChange,
  });

  @override
  Widget build(BuildContext context) {
    const Color bgSecondary = Color(0xFF161B22);
    const Color accentCyan = Color(0xFF58A6FF);
    const Color textPrimary = Color(0xFFC9D1D9);
    const Color textMuted = Color(0xFF8B949E);

    return CompositedTransformFollower(
      link: layerLink,
      showWhenUnlinked: false,
      offset: const Offset(0, -200),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 320),
          decoration: BoxDecoration(
            color: bgSecondary,
            border: Border.all(color: accentCyan.withOpacity(0.5), width: 1),
            borderRadius: BorderRadius.zero,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: commands.length,
            separatorBuilder: (_, __) => Divider(
              color: accentCyan.withOpacity(0.15),
              height: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
            ),
            itemBuilder: (context, index) {
              final cmd = commands[index];
              final isSelected = index == selectedIndex;
              return InkWell(
                onTap: () => onSelect(cmd),
                onHover: (_) => onIndexChange(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: isSelected ? accentCyan.withOpacity(0.1) : Colors.transparent,
                  child: Row(
                    children: [
                      Text(
                        cmd.name,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: isSelected ? accentCyan : textPrimary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cmd.description,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SlashCommand {
  final String name;
  final String description;

  SlashCommand(this.name, this.description);
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