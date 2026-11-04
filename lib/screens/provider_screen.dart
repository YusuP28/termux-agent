import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../models/provider_data.dart';
import '../services/storage_service.dart';
import '../widgets/provider_card.dart';

class ProviderScreen extends StatefulWidget {
  final String activeProviderId;
  final Function(String) onProviderSelected;

  const ProviderScreen({
    super.key,
    required this.activeProviderId,
    required this.onProviderSelected,
  });

  @override
  State<ProviderScreen> createState() => _ProviderScreenState();
}

class _ProviderScreenState extends State<ProviderScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    const Color bgPrimary = Color(0xFF0D1117);
    const Color bgSecondary = Color(0xFF161B22);
    const Color textPrimary = Color(0xFFC9D1D9);
    const Color textMuted = Color(0xFF8B949E);
    const Color accentCyan = Color(0xFF58A6FF);
    const Color accentGreen = Color(0xFF3FB950);

    final filteredProviders = allProviders.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             p.category.label.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text(
          'Kelola Provider',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFF58A6FF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF58A6FF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFC9D1D9),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Cari provider...',
                hintStyle: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF8B949E),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8B949E), size: 20),
                filled: true,
                fillColor: const Color(0xFF161B22),
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
                  borderSide: const BorderSide(color: Color(0xFF58A6FF), width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          // Provider list grouped by category
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: _buildCategorySections(filteredProviders),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategorySections(List<Provider> providers) {
    const Color bgSecondary = Color(0xFF161B22);
    const Color textPrimary = Color(0xFFC9D1D9);
    const Color textMuted = Color(0xFF8B949E);
    const Color accentCyan = Color(0xFF58A6FF);

    final categories = providers
        .map((p) => p.category)
        .toSet()
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return categories.map((category) {
      final categoryProviders = providers.where((p) => p.category == category).toList();
      if (categoryProviders.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  color: accentCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  category.label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF58A6FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${categoryProviders.length})',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF8B949E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // Provider grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categoryProviders.length,
            itemBuilder: (context, index) {
              final provider = categoryProviders[index];
              final isActive = provider.id == widget.activeProviderId;
              return ProviderCard(
                provider: provider,
                isActive: isActive,
                onTap: () => _showProviderConfig(provider),
              );
            },
          ),
          
          const SizedBox(height: 16),
        ],
      );
    }).toList();
  }

  void _showProviderConfig(Provider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ProviderConfigSheet(
        provider: provider,
        isActive: provider.id == widget.activeProviderId,
        onSetActive: () {
          widget.onProviderSelected(provider.id);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ProviderConfigSheet extends StatefulWidget {
  final Provider provider;
  final bool isActive;
  final VoidCallback onSetActive;

  const _ProviderConfigSheet({
    required this.provider,
    required this.isActive,
    required this.onSetActive,
  });

  @override
  State<_ProviderConfigSheet> createState() => _ProviderConfigSheetState();
}

class _ProviderConfigSheetState extends State<_ProviderConfigSheet> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _savedKey;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _loadSavedKey();
  }

  Future<void> _loadSavedKey() async {
    final key = await StorageService.getApiKey(widget.provider.id);
    setState(() => _savedKey = key);
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isLoading = true);
    await StorageService.saveApiKey(widget.provider.id, key);
    setState(() {
      _savedKey = key;
      _isLoading = false;
      _apiKeyController.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API Key disimpan'),
          backgroundColor: Color(0xFF3FB950),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteApiKey() async {
    await StorageService.deleteApiKey(widget.provider.id);
    setState(() => _savedKey = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API Key dihapus'),
          backgroundColor: Color(0xFF58A6FF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
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
    const Color accentRed = Color(0xFFF85149);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF30363D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Provider header
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF58A6FF).withOpacity(0.15),
                  border: Border.all(color: const Color(0xFF58A6FF), width: 1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  widget.provider.category.label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF58A6FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.provider.name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFFC9D1D9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF8B949E), size: 22),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Status & Auth type
          Row(
            children: <Widget>[
              _StatusChip(
                label: widget.provider.authTypeLabel,
                color: const Color(0xFF58A6FF),
              ),
              const SizedBox(width: 8),
              if (widget.provider.requiresApiKey)
                _StatusChip(
                  label: StorageService.hasApiKey(widget.provider.id)
                      ? 'Terhubung'
                      : 'Belum Terhubung',
                  color: StorageService.hasApiKey(widget.provider.id)
                      ? const Color(0xFF3FB950)
                      : const Color(0xFF8B949E),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Model selection
          const Text(
            'Model Default',
            style: TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF8B949E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
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
                value: widget.provider.defaultModel,
                dropdownColor: const Color(0xFF161B22),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFC9D1D9),
                  fontSize: 13,
                ),
                items: widget.provider.models.map((model) {
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
                onChanged: (value) {
                  // Update default model in storage
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // API Key section
          if (widget.provider.requiresApiKey) ...<Widget>[
            Row(
              children: <Widget>[
                const Text(
                  'API Key',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF8B949E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (StorageService.hasApiKey(widget.provider.id))
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFF85149)),
                    label: const Text(
                      'Hapus Key',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFFF85149),
                        fontSize: 11,
                      ),
                    ),
                    onPressed: () async {
                      await StorageService.deleteApiKey(widget.provider.id);
                      setState(() {});
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (StorageService.hasApiKey(widget.provider.id))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  border: Border.all(color: const Color(0xFF3FB950).withOpacity(0.5)),
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.check_circle, color: Color(0xFF3FB950), size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'API Key tersimpan',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF3FB950),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Status: Terhubung ✓',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF8B949E),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _apiKeyController,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFC9D1D9),
                      fontSize: 13,
                    ),
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Masukkan API Key...',
                      hintStyle: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF8B949E),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0D1117),
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
                        borderSide: const BorderSide(color: Color(0xFF58A6FF), width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save, color: Color(0xFF58A6FF), size: 20),
                        onPressed: _saveApiKey,
                      ),
                    ),
                  ),
                ],
              ),

          const SizedBox(height: 20),

          // Set as active button
          widget.isActive
              ? const SizedBox.shrink()
              : SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'Jadikan Provider Aktif',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: widget.onSetActive,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58A6FF),
                      foregroundColor: const Color(0xFF0D1117),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
              ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}