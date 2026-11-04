import 'package:flutter/material.dart';
import '../models/provider.dart';

class ProviderCard extends StatelessWidget {
  final Provider provider;
  final bool isActive;
  final VoidCallback onTap;

  const ProviderCard({
    super.key,
    required this.provider,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color bgPrimary = Color(0xFF0D1117);
    const Color bgSecondary = Color(0xFF161B22);
    const Color textPrimary = Color(0xFFC9D1D9);
    const Color textMuted = Color(0xFF8B949E);
    const Color accentCyan = Color(0xFF58A6FF);
    const Color accentGreen = Color(0xFF3FB950);
    const Color accentRed = Color(0xFFF85149);

    final hasApiKey = true; // Will be checked from storage in real implementation

    return Material(
      color: isActive ? accentCyan.withOpacity(0.1) : bgSecondary,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? accentCyan : const Color(0xFF30363D),
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Active badge + Auth type
              Row(
                children: [
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentCyan.withOpacity(0.15),
                        border: Border.all(color: accentCyan, width: 1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Text(
                        'AKTIF',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: accentCyan,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 44, height: 16),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getAuthTypeColor(provider.authType).withOpacity(0.15),
                      border: Border.all(color: _getAuthTypeColor(provider.authType), width: 1),
                    ),
                    child: Text(
                      provider.authTypeLabel,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: _getAuthTypeColor(provider.authType),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Provider name
              Text(
                provider.name,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFC9D1D9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Default model
              Text(
                provider.defaultModel,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF8B949E),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Bottom row: Status + Action
              Row(
                children: [
                  // Connection status
                  _ConnectionIndicator(
                    isConnected: true, // Will be dynamic
                    requiresKey: true,
                  ),
                  const Spacer(),
                  // Configure button
                  SizedBox(
                    width: 70,
                    height: 28,
                    child: TextButton(
                      onPressed: () {}, // Handled by parent
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: const Color(0xFF0D1117),
                        foregroundColor: accentCyan,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: accentCyan.withOpacity(0.5)),
                        ),
                      ),
                      child: const Text(
                        'ATUR',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAuthTypeColor(AuthType authType) {
    switch (authType) {
      case AuthType.apiKey:
        return const Color(0xFF58A6FF);
      case AuthType.oauth:
        return const Color(0xFFD29922);
      case AuthType.cookie:
        return const Color(0xFFF85149);
      case AuthType.none:
        return const Color(0xFF3FB950);
    }
  }
}

class _ConnectionIndicator extends StatelessWidget {
  final bool isConnected;
  final bool requiresKey;

  const _ConnectionIndicator({
    required this.isConnected,
    this.requiresKey = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? const Color(0xFF3FB950) : const Color(0xFF8B949E);
    final label = isConnected ? 'Terhubung' : 'Belum Terhubung';

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}