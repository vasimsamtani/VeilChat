import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veilchat/data/services/chat_security_service.dart';
import 'package:veilchat/ui/core/theme.dart';
import 'package:veilchat/ui/core/widgets/glass_card.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final secService = context.watch<ChatSecurityService>();

    return Scaffold(
      backgroundColor: VeilTheme.backgroundDeep,
      appBar: AppBar(
        title: const Text('Privacy & Stealth Controls'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Tactical Enclave Armed Banner (Stitch Screen 6 Group 1)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: VeilTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: VeilTheme.emeraldNeon.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: VeilTheme.emeraldNeon.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security_rounded, size: 20, color: VeilTheme.emeraldNeon),
                        SizedBox(width: 8),
                        Text(
                          'Cryptographic Vault',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: VeilTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VeilTheme.emeraldNeon.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: VeilTheme.emeraldNeon),
                          SizedBox(width: 5),
                          Text(
                            'TACTICAL ENCLAVE ARMED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: VeilTheme.emeraldNeon,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hardware keystore integrity verified. Decoy subsystem armed with zero persistent memory footprints.',
                  style: TextStyle(
                    fontSize: 12,
                    color: VeilTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VeilTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.memory_rounded, size: 13, color: VeilTheme.emeraldNeon),
                          SizedBox(width: 5),
                          Text(
                            'SecEnclave L4',
                            style: TextStyle(fontSize: 10.5, color: VeilTheme.textDim, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VeilTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.fingerprint_rounded, size: 13, color: VeilTheme.cyberCyan),
                          SizedBox(width: 5),
                          Text(
                            'AES-256-GCM',
                            style: TextStyle(fontSize: 10.5, color: VeilTheme.textDim, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Section 1: Individual Chat Locks
          _buildSectionHeader('INDIVIDUAL CHAT LOCKS (IN-FEED)'),
          const SizedBox(height: 8),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: secService.conversations.map((conv) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: const Color(0xFF1E2438),
                        backgroundImage: conv.avatarAssetPath != null
                            ? AssetImage(conv.avatarAssetPath!)
                            : null,
                        child: conv.avatarAssetPath == null
                            ? Text(
                                conv.avatarInitials,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conv.contactName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: VeilTheme.textPrimary,
                              ),
                            ),
                            Text(
                              conv.isLocked ? 'Visible & Locked with Biometrics' : 'Unrestricted preview',
                              style: TextStyle(
                                fontSize: 11,
                                color: conv.isLocked ? VeilTheme.lockedAmber : VeilTheme.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: conv.isLocked,
                        activeTrackColor: VeilTheme.lockedAmber.withValues(alpha: 0.5),
                        activeThumbColor: VeilTheme.lockedAmber,
                        onChanged: (_) => secService.toggleChatLock(conv.id),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Auto-Lock Timers
          _buildSectionHeader('AUTO-RELOCK TIMEOUT'),
          const SizedBox(height: 8),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automatically re-lock conversations after inactivity:',
                  style: TextStyle(
                    fontSize: 13,
                    color: VeilTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [15, 30, 60, 120].map((seconds) {
                    final isSelected = secService.autoLockSeconds == seconds;
                    return InkWell(
                      onTap: () => secService.setAutoLockSeconds(seconds),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? VeilTheme.primaryViolet
                              : VeilTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? VeilTheme.cyberCyan
                                : VeilTheme.surfaceBorder,
                          ),
                        ),
                        child: Text(
                          '${seconds}s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : VeilTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Dual PIN Architecture (Primary & Decoy)
          _buildSectionHeader('DUAL-PIN ARCHITECTURE (DURESS PROTECTION)'),
          const SizedBox(height: 8),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPinRow(
                  title: 'Primary Unlock PIN',
                  subtitle: 'Unlocks confidential messages and Vault',
                  pinValue: secService.primaryPin,
                  accentColor: VeilTheme.primaryViolet,
                  onEdit: () => _showChangePinDialog(
                    context,
                    title: 'Change Primary Security PIN',
                    isDecoy: false,
                    secService: secService,
                  ),
                ),
                const Divider(color: VeilTheme.surfaceBorder, height: 24),
                _buildPinRow(
                  title: 'Decoy / Duress PIN',
                  subtitle: 'Opens harmless fake chat (for coerced situations)',
                  pinValue: secService.decoyPin,
                  accentColor: VeilTheme.emeraldNeon,
                  onEdit: () => _showChangePinDialog(
                    context,
                    title: 'Change Decoy / Duress PIN',
                    isDecoy: true,
                    secService: secService,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: Stealth Notification Camouflage
          _buildSectionHeader('STEALTH NOTIFICATION CAMOUFLAGE'),
          const SizedBox(height: 8),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incoming messages from locked chats will disguise as:',
                  style: TextStyle(
                    fontSize: 13,
                    color: VeilTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDisguiseOption(
                  context,
                  secService,
                  'Google Calendar: Team Sync in 15m',
                  Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 8),
                _buildDisguiseOption(
                  context,
                  secService,
                  'System Update: Synced successfully',
                  Icons.system_update_alt_rounded,
                ),
                const SizedBox(height: 8),
                _buildDisguiseOption(
                  context,
                  secService,
                  'News Alert: Markets close higher today',
                  Icons.newspaper_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 5: Ghost Mode & Anti-Snoop
          _buildSectionHeader('GHOST MODE & WHATSAPP STEALTH ENGINE'),
          const SizedBox(height: 8),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Hide Blue Ticks (Read Receipts)
                Row(
                  children: [
                    const Icon(Icons.done_all_rounded, color: VeilTheme.cyberCyan),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ghost Read Receipts (No Blue Ticks)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: VeilTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Read incoming messages silently; senders only see double grey ticks',
                            style: TextStyle(
                              fontSize: 11,
                              color: VeilTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: secService.ghostReadReceipts,
                      activeTrackColor: VeilTheme.cyberCyan.withValues(alpha: 0.5),
                      activeThumbColor: VeilTheme.cyberCyan,
                      onChanged: (_) => secService.toggleGhostReadReceipts(),
                    ),
                  ],
                ),
                const Divider(color: VeilTheme.surfaceBorder, height: 20),

                // 2. Hide Status View (Stealth Story Viewer)
                Row(
                  children: [
                    const Icon(Icons.visibility_off_rounded, color: VeilTheme.emeraldNeon),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hide WhatsApp Status Views',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: VeilTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Watch contacts\' status updates without appearing in their viewer list',
                            style: TextStyle(
                              fontSize: 11,
                              color: VeilTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: secService.ghostStatusView,
                      activeTrackColor: VeilTheme.emeraldNeon.withValues(alpha: 0.5),
                      activeThumbColor: VeilTheme.emeraldNeon,
                      onChanged: (_) => secService.toggleGhostStatusView(),
                    ),
                  ],
                ),
                const Divider(color: VeilTheme.surfaceBorder, height: 20),

                // 3. Hide Typing & Audio Presence
                Row(
                  children: [
                    const Icon(Icons.keyboard_alt_outlined, color: VeilTheme.primaryViolet),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conceal Typing & Audio Presence',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: VeilTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Never broadcast "typing..." or "recording audio..." indicators',
                            style: TextStyle(
                              fontSize: 11,
                              color: VeilTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: secService.ghostTyping,
                      activeTrackColor: VeilTheme.primaryViolet.withValues(alpha: 0.5),
                      activeThumbColor: VeilTheme.primaryViolet,
                      onChanged: (_) => secService.toggleGhostTyping(),
                    ),
                  ],
                ),
                const Divider(color: VeilTheme.surfaceBorder, height: 20),

                // 4. View-Once Downloader & Auto-Vault
                Row(
                  children: [
                    const Icon(Icons.download_for_offline_rounded, color: VeilTheme.lockedAmber),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'View-Once Bypass & Auto-Downloader',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: VeilTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Bypass WhatsApp view-once restrictions & auto-save to encrypted Vault',
                            style: TextStyle(
                              fontSize: 11,
                              color: VeilTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: secService.autoSaveViewOnce,
                      activeTrackColor: VeilTheme.lockedAmber.withValues(alpha: 0.5),
                      activeThumbColor: VeilTheme.lockedAmber,
                      onChanged: (_) => secService.toggleAutoSaveViewOnce(),
                    ),
                  ],
                ),
                const Divider(color: VeilTheme.surfaceBorder, height: 20),

                // 5. Anti-Revoke (Deleted Message Keeper)
                Row(
                  children: [
                    const Icon(Icons.history_toggle_off_rounded, color: Color(0xFFFF5252)),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anti-Revoke Message Keeper',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: VeilTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Keep messages even if the sender clicks "Delete for Everyone"',
                            style: TextStyle(
                              fontSize: 11,
                              color: VeilTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: secService.antiRevokeMessages,
                      activeTrackColor: const Color(0xFFFF5252).withValues(alpha: 0.5),
                      activeThumbColor: const Color(0xFFFF5252),
                      onChanged: (_) => secService.toggleAntiRevokeMessages(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 6: App Permissions & Privacy Manifest
          _buildSectionHeader('APP PERMISSIONS & ZERO-KNOWLEDGE PRIVACY'),
          const SizedBox(height: 8),
          _buildPermissionsCard(context, secService),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: VeilTheme.textDim,
      ),
    );
  }

  Widget _buildPinRow({
    required String title,
    required String subtitle,
    required String pinValue,
    required Color accentColor,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VeilTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: VeilTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onEdit,
          child: Text(
            'PIN: $pinValue',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisguiseOption(
    BuildContext context,
    ChatSecurityService secService,
    String option,
    IconData icon,
  ) {
    final isSelected = secService.notificationDisguise == option;

    return InkWell(
      onTap: () => secService.setNotificationDisguise(option),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? VeilTheme.cyberCyan.withValues(alpha: 0.12)
              : VeilTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? VeilTheme.cyberCyan : VeilTheme.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? VeilTheme.cyberCyan : VeilTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? VeilTheme.textPrimary : VeilTheme.textSecondary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: VeilTheme.cyberCyan, size: 16),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog(
    BuildContext context, {
    required String title,
    required bool isDecoy,
    required ChatSecurityService secService,
  }) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMessage;
    bool obscurePins = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: VeilTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: VeilTheme.surfaceBorder, width: 1.2),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDecoy ? VeilTheme.emeraldNeon : VeilTheme.primaryViolet)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDecoy ? Icons.lock_open_rounded : Icons.shield_rounded,
                    color: isDecoy ? VeilTheme.emeraldNeon : VeilTheme.primaryViolet,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: VeilTheme.textPrimary,
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Step 1: Enter Current PIN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VeilTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: currentController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: obscurePins,
                    style: const TextStyle(fontSize: 18, letterSpacing: 6, color: VeilTheme.cyberCyan),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: VeilTheme.surfaceCard,
                      hintText: '••••',
                      hintStyle: const TextStyle(color: VeilTheme.textDim, letterSpacing: 4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Step 2: Enter New 4-Digit PIN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VeilTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: obscurePins,
                    style: const TextStyle(fontSize: 18, letterSpacing: 6, color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: VeilTheme.surfaceCard,
                      hintText: '••••',
                      hintStyle: const TextStyle(color: VeilTheme.textDim, letterSpacing: 4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Step 3: Confirm New PIN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VeilTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: obscurePins,
                    style: const TextStyle(fontSize: 18, letterSpacing: 6, color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: VeilTheme.surfaceCard,
                      hintText: '••••',
                      hintStyle: const TextStyle(color: VeilTheme.textDim, letterSpacing: 4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            obscurePins = !obscurePins;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              obscurePins ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 15,
                              color: VeilTheme.textDim,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              obscurePins ? 'Show PIN digits' : 'Hide PIN digits',
                              style: const TextStyle(fontSize: 11, color: VeilTheme.textDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: VeilTheme.errorRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: VeilTheme.errorRed.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: VeilTheme.errorRed, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: VeilTheme.errorRed, fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel', style: TextStyle(color: VeilTheme.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDecoy ? VeilTheme.emeraldNeon : VeilTheme.primaryViolet,
                  foregroundColor: isDecoy ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final current = currentController.text.trim();
                  final newPin = newController.text.trim();
                  final confirm = confirmController.text.trim();

                  if (current.length != 4) {
                    setState(() => errorMessage = 'Current PIN must be 4 digits');
                    return;
                  }
                  if (!secService.verifyPin(current, isDecoy: isDecoy)) {
                    setState(() => errorMessage = 'Current PIN is incorrect');
                    return;
                  }
                  if (newPin.length != 4) {
                    setState(() => errorMessage = 'New PIN must be 4 digits');
                    return;
                  }
                  if (newPin != confirm) {
                    setState(() => errorMessage = 'New PIN and Confirm PIN do not match');
                    return;
                  }

                  // Update PIN
                  final ok = secService.changePin(isDecoy: isDecoy, oldPin: current, newPin: newPin);
                  if (ok) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: VeilTheme.surfaceCard,
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: VeilTheme.emeraldNeon, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '$title successfully updated!',
                              style: const TextStyle(color: VeilTheme.textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Update PIN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionsCard(BuildContext context, ChatSecurityService secService) {
    final permissions = secService.grantedPermissions;

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded, color: VeilTheme.emeraldNeon, size: 18),
              SizedBox(width: 8),
              Text(
                'Individual Granular Permissions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: VeilTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Permissions are separated one-by-one. You decide exactly what to grant. VeilChat never accesses sensors or personal files without your explicit individual toggle.',
            style: TextStyle(fontSize: 11.5, color: VeilTheme.textSecondary, height: 1.4),
          ),
          const Divider(color: VeilTheme.surfaceBorder, height: 24),

          // Camera
          _buildPermissionItem(
            title: 'Camera Access',
            purpose: 'Taking encrypted photos & scanning WhatsApp Web QR code',
            privacyBadge: 'Local Memory Only',
            icon: Icons.camera_alt_rounded,
            isGranted: permissions['camera'] ?? false,
            onToggle: () => secService.togglePermission('camera'),
          ),
          const SizedBox(height: 12),

          // Gallery / Photos
          _buildPermissionItem(
            title: 'Photos & Gallery',
            purpose: 'Attaching photos and saving view-once media to Private Vault',
            privacyBadge: 'Zero Cloud Sync',
            icon: Icons.photo_library_rounded,
            isGranted: permissions['gallery'] ?? false,
            onToggle: () => secService.togglePermission('gallery'),
          ),
          const SizedBox(height: 12),

          // Files & Storage
          _buildPermissionItem(
            title: 'Files & Storage',
            purpose: 'Sending PDF contracts, files, and exporting offline vault items',
            privacyBadge: 'Enclave Sandboxed',
            icon: Icons.folder_shared_rounded,
            isGranted: permissions['files'] ?? false,
            onToggle: () => secService.togglePermission('files'),
          ),
          const SizedBox(height: 12),

          // Contacts
          _buildPermissionItem(
            title: 'Contacts Access',
            purpose: 'Resolving incoming WhatsApp numbers to names on-device',
            privacyBadge: 'Never Uploaded',
            icon: Icons.contacts_rounded,
            isGranted: permissions['contacts'] ?? false,
            onToggle: () => secService.togglePermission('contacts'),
          ),
          const SizedBox(height: 12),

          // Location
          _buildPermissionItem(
            title: 'Location Coordinates',
            purpose: 'Sending one-time encrypted location pins on demand',
            privacyBadge: 'No Background GPS',
            icon: Icons.location_on_rounded,
            isGranted: permissions['location'] ?? false,
            onToggle: () => secService.togglePermission('location'),
          ),
          const SizedBox(height: 12),

          // Microphone
          _buildPermissionItem(
            title: 'Microphone',
            purpose: 'Recording voice notes with real-time waveform visualization',
            privacyBadge: 'Encrypted Audio',
            icon: Icons.mic_rounded,
            isGranted: permissions['microphone'] ?? false,
            onToggle: () => secService.togglePermission('microphone'),
          ),

          const SizedBox(height: 16),
          // Privacy Manifest Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPrivacyManifestModal(context),
              icon: const Icon(Icons.privacy_tip_outlined, size: 16),
              label: const Text('View Comprehensive Privacy Manifest'),
              style: OutlinedButton.styleFrom(
                foregroundColor: VeilTheme.cyberCyan,
                side: BorderSide(color: VeilTheme.cyberCyan.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String purpose,
    required String privacyBadge,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onToggle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isGranted
                ? VeilTheme.cyberCyan.withValues(alpha: 0.15)
                : VeilTheme.surfaceBorder.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 19,
            color: isGranted ? VeilTheme.cyberCyan : VeilTheme.textDim,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: VeilTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: VeilTheme.emeraldNeon.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      privacyBadge,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: VeilTheme.emeraldNeon,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                purpose,
                style: const TextStyle(
                  fontSize: 11,
                  color: VeilTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: isGranted,
          activeTrackColor: VeilTheme.cyberCyan.withValues(alpha: 0.5),
          activeThumbColor: VeilTheme.cyberCyan,
          onChanged: (_) => onToggle(),
        ),
      ],
    );
  }

  void _showPrivacyManifestModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: VeilTheme.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: VeilTheme.surfaceBorderBright),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VeilTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.shield_rounded, color: VeilTheme.emeraldNeon, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'VeilChat Privacy Manifest',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VeilTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Why are permissions requested and how is your data protected?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VeilTheme.cyberCyan),
              ),
              const SizedBox(height: 10),
              _buildManifestItem(
                'Zero Cloud Telemetry',
                'VeilChat has no tracking SDKs, analytical trackers, or remote loggers. All data and cryptographic keys remain strictly on your physical device.',
              ),
              _buildManifestItem(
                'Media & File Isolation',
                'When you capture a photo or share a file, it is loaded directly into volatile RAM for end-to-end encryption. It is never added to the unencrypted public phone gallery.',
              ),
              _buildManifestItem(
                'Address Book Confidentiality',
                'Your contacts are only read locally to display names instead of raw phone numbers. VeilChat will never transmit your address book across any network.',
              ),
              _buildManifestItem(
                'Encrypted Storage Enclave',
                'Saved vault photos and offline messages are stored using AES-256-GCM authenticated encryption, backed by hardware keystore keys.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VeilTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('I Understand & Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManifestItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: VeilTheme.emeraldNeon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeilTheme.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11.5, color: VeilTheme.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
