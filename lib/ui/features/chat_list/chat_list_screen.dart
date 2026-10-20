import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veilchat/data/models/chat_model.dart';
import 'package:veilchat/data/services/chat_security_service.dart';
import 'package:veilchat/data/services/whatsapp_bridge_service.dart';
import 'package:veilchat/ui/core/theme.dart';
import 'package:veilchat/ui/core/widgets/shimmer_redaction.dart';
import 'package:veilchat/ui/features/auth/security_keypad_modal.dart';
import 'package:veilchat/ui/features/bridge/bridge_screen.dart';
import 'package:veilchat/ui/features/conversation/conversation_screen.dart';
import 'package:veilchat/ui/features/settings/privacy_settings_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final secService = context.watch<ChatSecurityService>();
    final conversations = secService.conversations;

    // Filter logic
    final filtered = conversations.where((c) {
      if (_activeFilter == 'Locked') return c.isLocked;
      if (_activeFilter == 'Unread') return c.unreadCount > 0;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: VeilTheme.backgroundDeep,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: VeilTheme.surfaceDark.withValues(alpha: 0.85),
        titleSpacing: 16,
        title: Row(
          children: [
            // User Avatar with WhatsApp Linked Status Dot
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BridgeScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFF1E2438),
                    child: Text(
                      'VC',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: VeilTheme.cyberCyan,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: VeilTheme.emeraldNeon,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: VeilTheme.surfaceDark,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // VeilChat Monogram Wordmark
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, VeilTheme.cyberCyan],
                  ).createShader(bounds),
                  child: const Text(
                    'VeilChat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: VeilTheme.primaryViolet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: VeilTheme.primaryViolet.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 10, color: VeilTheme.lockedAmber),
                      SizedBox(width: 3),
                      Text(
                        'VEIL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: VeilTheme.lockedAmber,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Bridge QR Pairing Shortcut
          IconButton(
            tooltip: 'WhatsApp Multi-Device Bridge',
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BridgeScreen()),
              );
            },
          ),
          // Privacy Settings Button
          IconButton(
            tooltip: 'Privacy & Stealth Settings',
            icon: const Icon(Icons.shield_outlined, size: 22, color: VeilTheme.cyberCyan),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Screen 2 Ambient Strip: Secure Channel & AES-GCM-256
          _buildAmbientStrip(),

          // Filter Tabs & Ghost Mode Pill Bar
          _buildFilterBar(secService, conversations),

          // Chat Feed List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context, secService)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: filtered.length + 1, // +1 for the zero-knowledge enclave footer card
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return _buildEnclaveStatusCard();
                      }
                      final conv = filtered[index];
                      return _buildConversationRow(context, conv, secService);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () => _showNewChatDialog(context, secService),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: VeilTheme.brandGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: VeilTheme.primaryViolet.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildAmbientStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: VeilTheme.surfaceDark.withValues(alpha: 0.7),
        border: const Border(
          bottom: BorderSide(color: VeilTheme.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: VeilTheme.emeraldNeon,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VeilTheme.emeraldNeon,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'SECURE CHANNEL • SHIELD ACTIVE',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: VeilTheme.textDim,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: VeilTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: VeilTheme.surfaceBorder,
                width: 0.8,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, size: 12, color: VeilTheme.emeraldNeon),
                SizedBox(width: 5),
                Text(
                  'AES-GCM-256',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: VeilTheme.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ChatSecurityService secService, List<ChatConversation> conversations) {
    final lockedCount = conversations.where((c) => c.isLocked).length;
    final unreadCount = conversations.where((c) => c.unreadCount > 0).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: VeilTheme.surfaceDark.withValues(alpha: 0.5),
        border: const Border(
          bottom: BorderSide(color: VeilTheme.surfaceBorder, width: 0.8),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Filter Chips
            _buildFilterChip('All', count: 14),
            const SizedBox(width: 8),
            _buildFilterChip('Locked', icon: Icons.lock_rounded, count: lockedCount),
            const SizedBox(width: 8),
            _buildFilterChip('Unread', count: unreadCount > 0 ? unreadCount : null),

            const SizedBox(width: 16),

            // Ghost Mode Quick Toggle Pill
            InkWell(
              onTap: secService.toggleGhostMode,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: secService.globalGhostMode
                      ? VeilTheme.cyberCyan.withValues(alpha: 0.18)
                      : VeilTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: secService.globalGhostMode
                        ? VeilTheme.cyberCyan
                        : VeilTheme.surfaceBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off_rounded,
                      size: 13,
                      color: secService.globalGhostMode
                          ? VeilTheme.cyberCyan
                          : VeilTheme.textDim,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Stealth',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secService.globalGhostMode
                            ? VeilTheme.cyberCyan
                            : VeilTheme.textDim,
                        letterSpacing: 0.3,
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

  Widget _buildFilterChip(String label, {IconData? icon, int? count}) {
    final isSelected = _activeFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? VeilTheme.primaryViolet
              : VeilTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? VeilTheme.primaryViolet
                : VeilTheme.surfaceBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected ? Colors.white : VeilTheme.cyberCyan,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : VeilTheme.textSecondary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : VeilTheme.surfaceBorderBright,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : VeilTheme.cyberCyan,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConversationRow(
    BuildContext context,
    ChatConversation conv,
    ChatSecurityService secService,
  ) {
    if (conv.id == 'sarah_m') {
      return _buildHeroLockedRow(context, conv, secService);
    } else if (conv.id == 'emily_c') {
      return _buildProtectedRow(context, conv, secService);
    } else {
      return _buildNormalRow(context, conv, secService);
    }
  }

  // Chat 2: Hero Locked Chat - Sarah Miller (High Luxury Vault)
  Widget _buildHeroLockedRow(
    BuildContext context,
    ChatConversation conv,
    ChatSecurityService secService,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          SecurityKeypadModal.show(
            context,
            chatId: conv.id,
            contactName: conv.contactName,
            avatarInitials: conv.avatarInitials,
            avatarAssetPath: conv.avatarAssetPath,
          );
        },
        onLongPress: () => _showChatOptionsSheet(context, conv, secService),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VeilTheme.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: VeilTheme.primaryViolet.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: VeilTheme.primaryViolet.withValues(alpha: 0.12),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar with Luminous Aura & Shield Badge
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [VeilTheme.cyberCyan, VeilTheme.primaryViolet],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF1E2438),
                          backgroundImage: conv.avatarAssetPath != null
                              ? AssetImage(conv.avatarAssetPath!)
                              : null,
                          child: conv.avatarAssetPath == null
                              ? Text(
                                  conv.avatarInitials,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: VeilTheme.cyberCyan,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            size: 10,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Contact Name & Vault Badge & Timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      conv.contactName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: VeilTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: VeilTheme.cyberCyan.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Vault',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: VeilTheme.cyberCyan,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: VeilTheme.cyberCyan,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  conv.lastMessageTime,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: VeilTheme.cyberCyan,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Redacted Waveform Shimmer Pill
                        ShimmerRedaction(
                          label: 'Tap to unlock conversation',
                          showWaveform: true,
                          icon: Icons.fingerprint_rounded,
                          onTap: () {
                            SecurityKeypadModal.show(
                              context,
                              chatId: conv.id,
                              contactName: conv.contactName,
                              avatarInitials: conv.avatarInitials,
                              avatarAssetPath: conv.avatarAssetPath,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Whisper Text Footer
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: VeilTheme.emeraldNeon,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Biometric Secured • Hardware E2EE',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: VeilTheme.textDim.withValues(alpha: 0.85),
                        letterSpacing: 0.2,
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

  // Chat 4: Protected Chat - Dr. Emily Chen
  Widget _buildProtectedRow(
    BuildContext context,
    ChatConversation conv,
    ChatSecurityService secService,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          SecurityKeypadModal.show(
            context,
            chatId: conv.id,
            contactName: conv.contactName,
            avatarInitials: conv.avatarInitials,
            avatarAssetPath: conv.avatarAssetPath,
          );
        },
        onLongPress: () => _showChatOptionsSheet(context, conv, secService),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: VeilTheme.surfaceBorder, width: 0.6),
            ),
          ),
          child: Row(
            children: [
              // Avatar with Blurred Lock Overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF1E2438),
                    backgroundImage: conv.avatarAssetPath != null
                        ? AssetImage(conv.avatarAssetPath!)
                        : null,
                    child: conv.avatarAssetPath == null
                        ? Text(
                            conv.avatarInitials,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 17,
                      color: VeilTheme.primaryViolet,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  conv.contactName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: VeilTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: VeilTheme.primaryViolet,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conv.lastMessageTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: VeilTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ShimmerRedaction(
                      label: 'Tap to unlock conversation',
                      showWaveform: false,
                      icon: Icons.lock_rounded,
                      trailingTag: 'AUTH',
                      onTap: () {
                        SecurityKeypadModal.show(
                          context,
                          chatId: conv.id,
                          contactName: conv.contactName,
                          avatarInitials: conv.avatarInitials,
                          avatarAssetPath: conv.avatarAssetPath,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Normal Chat Rows: David Clark, Alex Rivera
  Widget _buildNormalRow(
    BuildContext context,
    ChatConversation conv,
    ChatSecurityService secService,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConversationScreen(
                chatId: conv.id,
                isDecoy: false,
              ),
            ),
          );
        },
        onLongPress: () => _showChatOptionsSheet(context, conv, secService),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: VeilTheme.surfaceBorder, width: 0.6),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF1E2438),
                    backgroundImage: conv.avatarAssetPath != null
                        ? AssetImage(conv.avatarAssetPath!)
                        : null,
                    child: conv.avatarAssetPath == null
                        ? Text(
                            conv.avatarInitials,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  if (conv.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: VeilTheme.emeraldNeon,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: VeilTheme.backgroundDeep,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            conv.contactName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: VeilTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conv.lastMessageTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: VeilTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: VeilTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: VeilTheme.cyberCyan,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnclaveStatusCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VeilTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VeilTheme.surfaceBorder,
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: VeilTheme.emeraldNeon.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.memory_rounded,
              color: VeilTheme.emeraldNeon,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zero-Knowledge Enclave',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: VeilTheme.textPrimary,
                  ),
                ),
                Text(
                  'Keys never transit external servers',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: VeilTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: VeilTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: VeilTheme.primaryViolet.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: const Text(
              'Audit',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: VeilTheme.primaryViolet,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatOptionsSheet(
    BuildContext context,
    ChatConversation conv,
    ChatSecurityService secService,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VeilTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    conv.isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: VeilTheme.lockedAmber,
                  ),
                  title: Text(
                    conv.isLocked ? 'Remove Chat Lock' : 'Lock Chat (Keep Visible)',
                    style: const TextStyle(color: VeilTheme.textPrimary),
                  ),
                  subtitle: Text(
                    conv.isLocked
                        ? 'Remove biometric & PIN protection'
                        : 'Guard behind biometrics while keeping on feed',
                    style: const TextStyle(color: VeilTheme.textDim, fontSize: 11),
                  ),
                  onTap: () {
                    secService.toggleChatLock(conv.id);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: VeilTheme.cyberCyan),
                  title: const Text('Open Security Keypad', style: TextStyle(color: VeilTheme.textPrimary)),
                  onTap: () {
                    Navigator.of(context).pop();
                    SecurityKeypadModal.show(
                      context,
                      chatId: conv.id,
                      contactName: conv.contactName,
                      avatarInitials: conv.avatarInitials,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ChatSecurityService secService) {
    final bridge = context.watch<WhatsAppBridgeService>();
    final isLinked = bridge.isAuthenticated;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: VeilTheme.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLinked ? VeilTheme.emeraldNeon : VeilTheme.primaryViolet,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isLinked ? VeilTheme.emeraldNeon : VeilTheme.primaryViolet).withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isLinked ? Icons.mark_chat_read_rounded : Icons.chat_bubble_outline_rounded,
                size: 38,
                color: isLinked ? VeilTheme.emeraldNeon : VeilTheme.cyberCyan,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isLinked ? 'WhatsApp Linked & Active' : 'No Conversations Yet',
              style: const TextStyle(
                color: VeilTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isLinked
                  ? 'Your WhatsApp is securely paired (${bridge.userName ?? 'User'}).\nStart a new conversation or send a message from your phone.'
                  : 'Pair your WhatsApp account in the top-left settings or tap below to start a new encrypted chat.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: VeilTheme.textDim,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: VeilTheme.cyberCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_comment_rounded, size: 20),
              label: const Text(
                'Start New Chat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () => _showNewChatDialog(context, secService),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context, ChatSecurityService secService) {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: VeilTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VeilTheme.surfaceBorder, width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: VeilTheme.cyberCyan),
            SizedBox(width: 10),
            Text(
              'New WhatsApp Chat',
              style: TextStyle(color: VeilTheme.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter phone number with country code (e.g. 919876543210):',
              style: TextStyle(color: VeilTheme.textDim, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              style: const TextStyle(color: VeilTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 919879151961',
                hintStyle: const TextStyle(color: VeilTheme.textDim),
                prefixIcon: const Icon(Icons.phone_rounded, color: VeilTheme.cyberCyan, size: 20),
                filled: true,
                fillColor: VeilTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VeilTheme.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VeilTheme.cyberCyan),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: VeilTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Contact Name (Optional)',
                hintStyle: const TextStyle(color: VeilTheme.textDim),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: VeilTheme.textSecondary, size: 20),
                filled: true,
                fillColor: VeilTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VeilTheme.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VeilTheme.cyberCyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: VeilTheme.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VeilTheme.cyberCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final rawPhone = phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
              if (rawPhone.isEmpty) return;

              final jid = '$rawPhone@s.whatsapp.net';
              final name = nameController.text.trim().isNotEmpty
                  ? nameController.text.trim()
                  : rawPhone;

              final conv = secService.createOrGetConversation(jid, name);

              // Notify bridge
              try {
                final bridge = context.read<WhatsAppBridgeService>();
                bridge.startChat(jid, name);
              } catch (_) {}

              Navigator.of(dialogCtx).pop();

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConversationScreen(
                    chatId: conv.id,
                    isDecoy: false,
                  ),
                ),
              );
            },
            child: const Text('Start Chat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
