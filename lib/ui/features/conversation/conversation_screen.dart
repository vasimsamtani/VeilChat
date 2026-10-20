import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veilchat/data/models/chat_model.dart';
import 'package:veilchat/data/services/chat_security_service.dart';
import 'package:veilchat/data/services/whatsapp_bridge_service.dart';
import 'package:veilchat/ui/core/theme.dart';

class ConversationScreen extends StatefulWidget {
  final String chatId;
  final bool isDecoy;

  const ConversationScreen({
    super.key,
    required this.chatId,
    this.isDecoy = false,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final secService = context.read<ChatSecurityService>();
    secService.sendMessage(widget.chatId, text);

    // If real conversation (not in decoy mode), also forward to WhatsApp Bridge if connected
    if (!widget.isDecoy) {
      try {
        final bridgeService = context.read<WhatsAppBridgeService>();
        if (bridgeService.isAuthenticated) {
          bridgeService.sendMessage(widget.chatId, text);
        }
      } catch (_) {}
    }

    _textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onInstantLock() {
    final secService = context.read<ChatSecurityService>();
    secService.lockCurrentChat();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final secService = context.watch<ChatSecurityService>();

    // If chat was locked externally or timed out, pop automatically
    if (!secService.isChatUnlocked(widget.chatId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
    }

    final conversation = secService.conversations.firstWhere(
      (c) => c.id == widget.chatId,
      orElse: () => ChatConversation(
        id: widget.chatId,
        contactName: widget.chatId.split('@')[0],
        avatarInitials: 'WA',
        isOnline: true,
        isLocked: false,
        isVerified: false,
        unreadCount: 0,
        lastMessageTime: 'Just now',
        previewText: '',
        realMessages: [],
        decoyMessages: [],
      ),
    );

    final messages = widget.isDecoy
        ? conversation.decoyMessages
        : conversation.realMessages;

    final remainingSec = secService.remainingLockSeconds;
    final totalSec = secService.autoLockSeconds;
    final timerProgress = totalSec > 0 ? (remainingSec / totalSec).clamp(0.0, 1.0) : 1.0;

    final bool isDecoy = widget.isDecoy;

    return Scaffold(
      backgroundColor: VeilTheme.backgroundDeep,
      appBar: isDecoy ? _buildDecoyAppBar(conversation) : _buildRealAppBar(conversation, timerProgress, remainingSec),
      body: Stack(
        children: [
          // Security Watermark for Real Unlocked view
          if (!isDecoy)
            Positioned(
              top: 10,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: VeilTheme.surfaceBorder,
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 11,
                      color: VeilTheme.textDim,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Protected View',
                      style: TextStyle(
                        fontSize: 10,
                        color: VeilTheme.textDim,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Message Stream
          Column(
            children: [
              // Security status pill banner (Real mode)
              if (!isDecoy) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: VeilTheme.surfaceCard.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: VeilTheme.surfaceBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: VeilTheme.emeraldNeon,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'E2EE Hardware-Isolated Session • Auto-Lock (${remainingSec}s)',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: VeilTheme.textDim,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: VeilTheme.surfaceCard.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Today • Hardware Enclave Synced',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: VeilTheme.textDim,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: VeilTheme.surfaceCard.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Today, October 24',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: VeilTheme.textDim,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: messages.length + (isDecoy ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isDecoy && index == messages.length) {
                      return _buildTypingIndicator();
                    }
                    final msg = messages[index];
                    return _buildMessageItem(msg, secService, isDecoy);
                  },
                ),
              ),

              // Bottom Input Bar
              _buildInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDecoyAppBar(ChatConversation conversation) {
    return AppBar(
      backgroundColor: VeilTheme.surfaceDark.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFF1E2438),
                backgroundImage: const AssetImage('assets/images/sarah_miller.jpg'),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        conversation.contactName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: VeilTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: VeilTheme.cyberCyan,
                    ),
                  ],
                ),
                const Text(
                  'Active now',
                  style: TextStyle(
                    fontSize: 11,
                    color: VeilTheme.emeraldNeon,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_rounded, size: 20, color: VeilTheme.textSecondary),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.videocam_rounded, size: 22, color: VeilTheme.textSecondary),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 20, color: VeilTheme.textSecondary),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  PreferredSizeWidget _buildRealAppBar(ChatConversation conversation, double timerProgress, int remainingSec) {
    return AppBar(
      backgroundColor: VeilTheme.surfaceDark.withValues(alpha: 0.9),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: _onInstantLock,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Contact Avatar with Auto-Lock Depleting Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  value: timerProgress,
                  strokeWidth: 2.5,
                  backgroundColor: VeilTheme.surfaceBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    timerProgress < 0.25 ? VeilTheme.errorRed : VeilTheme.cyberCyan,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF1E2438),
                backgroundImage: conversation.avatarAssetPath != null
                    ? AssetImage(conversation.avatarAssetPath!)
                    : null,
                child: conversation.avatarAssetPath == null
                    ? Text(
                        conversation.avatarInitials,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.contactName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: VeilTheme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: conversation.isOnline
                            ? VeilTheme.emeraldNeon
                            : VeilTheme.textDim,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Unlocked • Auto-locks in ${remainingSec}s',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: remainingSec <= 10
                              ? VeilTheme.errorRed
                              : VeilTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Instant Relock Shield Button
        IconButton(
          tooltip: 'Instant Re-Lock Now',
          icon: const Icon(
            Icons.shield_outlined,
            color: VeilTheme.lockedAmber,
            size: 22,
          ),
          onPressed: _onInstantLock,
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: VeilTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(150),
                const SizedBox(width: 4),
                _buildDot(300),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Sarah is typing...',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: VeilTheme.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: VeilTheme.primaryViolet,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg, ChatSecurityService secService, bool isDecoy) {
    if (msg.isViewOnce) {
      return _buildViewOnceCard(msg, secService);
    }

    if (msg.mediaAssetPath != null) {
      return _buildMediaMessageCard(msg, secService);
    }

    final isMe = msg.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? null : VeilTheme.surfaceCard,
          gradient: isMe ? VeilTheme.brandGradient : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: VeilTheme.surfaceBorder,
                  width: 1,
                ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: VeilTheme.primaryViolet.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(
                color: VeilTheme.textPrimary,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isDecoy && !isMe) ...[
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 11,
                    color: VeilTheme.emeraldNeon,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'ISOLATED ENCLAVE',
                    style: TextStyle(
                      color: VeilTheme.textDim,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (!isDecoy && isMe) ...[
                  const Text(
                    'ECDSA-521',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  msg.timestamp,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : VeilTheme.textDim,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all_rounded,
                    size: 13,
                    color: secService.globalGhostMode
                        ? Colors.white.withValues(alpha: 0.6)
                        : VeilTheme.cyberCyan,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Media attachment bubble for Decoy groceries (Stitch Screen 5)
  Widget _buildMediaMessageCard(ChatMessage msg, ChatSecurityService secService) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: VeilTheme.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: VeilTheme.surfaceBorder,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Attachment
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  child: Image.asset(
                    msg.mediaAssetPath!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Size Badge Overlay
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg.mediaSize ?? '1.4 MB',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Caption text
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: const TextStyle(
                      color: VeilTheme.textPrimary,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    msg.timestamp,
                    style: const TextStyle(
                      color: VeilTheme.textDim,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ephemeral View-Once Document Card (Stitch Screen 4)
  Widget _buildViewOnceCard(ChatMessage msg, ChatSecurityService secService) {
    final isSaved = msg.isSavedToVault;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VeilTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: VeilTheme.primaryViolet.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Countdown Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: VeilTheme.errorRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: VeilTheme.errorRed),
                    SizedBox(width: 5),
                    Text(
                      'Expiring in 02:58',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: VeilTheme.errorRed,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.shield_rounded, size: 13, color: VeilTheme.emeraldNeon),
                  SizedBox(width: 4),
                  Text(
                    'Self-Destruct',
                    style: TextStyle(
                      fontSize: 11,
                      color: VeilTheme.textDim,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Privacy Blurred Preview Box
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: VeilTheme.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: VeilTheme.surfaceBorder,
                width: 0.8,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: VeilTheme.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VeilTheme.primaryViolet.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.visibility_off_rounded,
                    color: VeilTheme.primaryViolet,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Encrypted View-Once Document',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: VeilTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Tap and hold to preview securely',
                  style: TextStyle(
                    fontSize: 11,
                    color: VeilTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Controls: Save to Private Vault & Immediate Purge
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: isSaved ? null : () => secService.saveViewOnceToVault(msg.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSaved
                          ? VeilTheme.emeraldNeon.withValues(alpha: 0.15)
                          : VeilTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSaved
                            ? VeilTheme.emeraldNeon
                            : VeilTheme.primaryViolet.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSaved ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                          size: 15,
                          color: isSaved ? VeilTheme.emeraldNeon : VeilTheme.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSaved ? 'Saved in Veil Vault' : 'Save to Private Vault',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSaved
                                ? VeilTheme.emeraldNeon
                                : VeilTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VeilTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: VeilTheme.surfaceBorder,
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: VeilTheme.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: VeilTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: VeilTheme.surfaceBorder, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: VeilTheme.textSecondary),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: VeilTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: VeilTheme.surfaceBorder, width: 1),
                ),
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_) => _onSendMessage(),
                  style: const TextStyle(
                    color: VeilTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type an encrypted message...',
                    hintStyle: TextStyle(
                      color: VeilTheme.textDim,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: VeilTheme.brandGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: _onSendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
