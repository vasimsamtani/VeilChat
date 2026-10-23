import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:veilchat/data/services/whatsapp_bridge_service.dart';
import 'package:veilchat/ui/core/theme.dart';
import 'package:veilchat/ui/core/widgets/glass_card.dart';

class BridgeScreen extends StatefulWidget {
  const BridgeScreen({super.key});

  @override
  State<BridgeScreen> createState() => _BridgeScreenState();
}

class _BridgeScreenState extends State<BridgeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bridge = context.watch<WhatsAppBridgeService>();

    return Scaffold(
      backgroundColor: VeilTheme.backgroundDeep,
      appBar: AppBar(
        title: const Text('WhatsApp Multi-Device Bridge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_rounded, size: 20),
            tooltip: 'Server Endpoint',
            onPressed: () => _showServerUrlDialog(context, bridge),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reconnect Bridge',
            onPressed: () => bridge.connect(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Status Banner
            _buildStatusBanner(bridge),
            const SizedBox(height: 24),

            // Animated QR Code Card / Connected Status Card
            GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: bridge.isAuthenticated
                  ? _buildConnectedCard(bridge)
                  : _buildQrCard(bridge),
            ),
            const SizedBox(height: 24),

            // Step-by-Step Instructions
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to pair your phone:',
                    style: TextStyle(
                      color: VeilTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildStep('1', 'Open WhatsApp on your mobile phone'),
                  const SizedBox(height: 10),
                  _buildStep('2', 'Navigate to Settings > Linked Devices'),
                  const SizedBox(height: 10),
                  _buildStep('3', 'Tap "Link a Device" and scan the QR code above'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Zero-Knowledge Security Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VeilTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VeilTheme.surfaceBorder),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_clock_outlined, color: VeilTheme.cyberCyan, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Zero-Knowledge Multi-Device Protocol: Your private keys never touch cloud servers. WhatsApp E2EE traffic connects directly between your local bridge and WhatsApp servers.',
                      style: TextStyle(
                        fontSize: 12,
                        color: VeilTheme.textSecondary,
                        height: 1.4,
                      ),
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

  Widget _buildStatusBanner(WhatsAppBridgeService bridge) {
    Color bannerColor;
    IconData icon;
    String text;

    if (bridge.isAuthenticated) {
      bannerColor = VeilTheme.emeraldNeon;
      icon = Icons.verified_user_rounded;
      text = 'WhatsApp Linked: ${bridge.userName ?? bridge.userJid ?? "Active"}';
    } else if (bridge.waStatus == WhatsAppAuthStatus.qrReady) {
      bannerColor = VeilTheme.cyberCyan;
      icon = Icons.qr_code_scanner_rounded;
      text = 'Local Bridge Online • Scan QR to Link';
    } else if (bridge.socketStatus == BridgeSocketStatus.connecting) {
      bannerColor = const Color(0xFFFFB74D);
      icon = Icons.sync_rounded;
      text = 'Connecting to Local Bridge (ws://127.0.0.1:5055)...';
    } else {
      bannerColor = VeilTheme.errorRed;
      icon = Icons.cloud_off_rounded;
      text = 'Bridge Daemon Offline • Start with: node server/bridge.js';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bannerColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: bannerColor, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: bannerColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(WhatsAppBridgeService bridge) {
    if (bridge.socketStatus == BridgeSocketStatus.disconnected) {
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withValues(alpha: 0.12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 40,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Bridge Server Offline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: VeilTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'To generate a live WhatsApp QR code on Android,\nconnect to your PC on Wi-Fi or Cloud Server.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: VeilTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showServerUrlDialog(context, bridge),
            icon: const Icon(Icons.wifi_rounded, size: 18),
            label: const Text('Connect to PC (Wi-Fi) or Cloud'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VeilTheme.cyberCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => bridge.connect(),
            icon: const Icon(Icons.refresh_rounded, size: 16, color: VeilTheme.textDim),
            label: const Text('Retry Connection', style: TextStyle(color: VeilTheme.textDim, fontSize: 12)),
          ),
        ],
      );
    }

    if (bridge.qrCode == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            CircularProgressIndicator(color: VeilTheme.cyberCyan),
            SizedBox(height: 20),
            Text(
              'Generating WhatsApp QR Code...',
              style: TextStyle(
                color: VeilTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Connecting securely to WhatsApp multi-device gateway...',
              style: TextStyle(color: VeilTheme.textDim, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Container holding real QR
            Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x30000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: QrImageView(
                data: bridge.qrCode!,
                version: QrVersions.auto,
                size: 200,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),

            // Animated Laser Scan Bar
            AnimatedBuilder(
              animation: _laserController,
              builder: (context, child) {
                final yOffset = (_laserController.value * 200.0) - 100.0;
                return Transform.translate(
                  offset: Offset(0, yOffset),
                  child: Container(
                    width: 210,
                    height: 3,
                    decoration: BoxDecoration(
                      color: VeilTheme.cyberCyan,
                      boxShadow: [
                        BoxShadow(
                          color: VeilTheme.cyberCyan.withValues(alpha: 0.8),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Scan with WhatsApp to Pair',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: VeilTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Scan this live QR code with your phone camera in WhatsApp > Linked Devices.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: VeilTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedCard(WhatsAppBridgeService bridge) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VeilTheme.emeraldNeon.withValues(alpha: 0.15),
            border: Border.all(
              color: VeilTheme.emeraldNeon,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: VeilTheme.emeraldNeon.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: VeilTheme.emeraldNeon,
            size: 40,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Connected & Authenticated',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: VeilTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Linked Account: ${bridge.userName ?? bridge.userJid ?? "WhatsApp User"}',
          style: const TextStyle(
            fontSize: 14,
            color: VeilTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: VeilTheme.primaryViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Open Encrypted Feed'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => bridge.logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: VeilTheme.errorRed,
                side: const BorderSide(color: VeilTheme.errorRed),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Unlink Device'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            gradient: VeilTheme.brandGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: VeilTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _showServerUrlDialog(BuildContext context, WhatsAppBridgeService bridge) {
    final controller = TextEditingController(text: bridge.bridgeUrl);
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
            Icon(Icons.cloud_outlined, color: VeilTheme.cyberCyan),
            SizedBox(width: 10),
            Text(
              'Bridge Server Endpoint',
              style: TextStyle(color: VeilTheme.textPrimary, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect to your Cloud Bridge or local PC:',
              style: TextStyle(color: VeilTheme.textDim, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: VeilTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. wss://veilchat.up.railway.app',
                hintStyle: const TextStyle(color: VeilTheme.textDim),
                prefixIcon: const Icon(Icons.link_rounded, color: VeilTheme.cyberCyan, size: 20),
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
            const SizedBox(height: 12),
            Row(
              children: [
                ActionChip(
                  label: const Text('Localhost', style: TextStyle(fontSize: 11)),
                  backgroundColor: VeilTheme.surfaceCard,
                  onPressed: () => controller.text = 'ws://127.0.0.1:5055',
                ),
              ],
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
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                bridge.updateBridgeUrl(newUrl);
              }
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Save & Connect', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
