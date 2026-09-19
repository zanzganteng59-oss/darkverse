import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:darkverse/theme/app_theme.dart';

class NglPage extends StatefulWidget {
  const NglPage({super.key});

  @override
  State<NglPage> createState() => _NglPageState();
}

class _NglPageState extends State<NglPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isRunning = false;
  int counter = 0;
  String statusLog = "";
  Timer? timer;

  String generateDeviceId(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  Future<void> sendMessage(String username, String message) async {
    final deviceId = generateDeviceId(42);
    final url = Uri.parse("https://ngl.link/api/submit");

    final headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0",
      "Accept": "*/*",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "X-Requested-With": "XMLHttpRequest",
      "Referer": "https://ngl.link/$username",
      "Origin": "https://ngl.link"
    };

    final body =
        "username=$username&question=$message&deviceId=$deviceId&gameSlug=&referrer=";

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        setState(() {
          counter++;
          statusLog = "✅ [$counter] Pesan terkirim";
        });
      } else {
        setState(() {
          statusLog = "❌ Ratelimit (${response.statusCode}), tunggu 5 detik...";
        });
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      setState(() {
        statusLog = "⚠️ Error: $e";
      });
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void startLoop() {
    final username = usernameController.text.trim();
    final message = messageController.text.trim();

    if (username.isEmpty || message.isEmpty) {
      setState(() {
        statusLog = "⚠️ Harap isi username & pesan!";
      });
      return;
    }

    setState(() {
      isRunning = true;
      counter = 0;
      statusLog = "▶️ Mulai mengirim...";
    });

    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isRunning) {
        sendMessage(username, message);
      }
    });
  }

  void stopLoop() {
    setState(() {
      isRunning = false;
      statusLog = "⏹️ Dihentikan.";
    });
    timer?.cancel();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Text("NGL Auto Sender", style: AppTheme.headingM),
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecor(),
                child: Column(
                  children: [
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "Username NGL",
                        labelStyle: TextStyle(color: AppTheme.teal),
                        hintText: "contoh: username_ngl",
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.borderSubtle),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.teal, width: 2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        filled: true,
                        fillColor: AppTheme.bgInput,
                        prefixIcon: Icon(Icons.person, color: AppTheme.teal),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "Pesan",
                        labelStyle: TextStyle(color: AppTheme.teal),
                        hintText: "Masukkan pesan yang ingin dikirim...",
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.borderSubtle),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.teal, width: 2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        filled: true,
                        fillColor: AppTheme.bgInput,
                        prefixIcon: Icon(Icons.message, color: AppTheme.teal),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecor(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isRunning ? null : startLoop,
                        icon: const Icon(Icons.play_arrow, color: AppTheme.bgDeep),
                        label: const Text(
                          "START",
                          style: TextStyle(
                            color: AppTheme.bgDeep,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: AppTheme.primaryButton(AppTheme.mint),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isRunning ? stopLoop : null,
                        icon: const Icon(Icons.stop, color: AppTheme.bgDeep),
                        label: const Text(
                          "STOP",
                          style: TextStyle(
                            color: AppTheme.bgDeep,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: AppTheme.primaryButton(AppTheme.coral),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecor(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient(AppTheme.teal),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.textPrimary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "STATUS LOG",
                              style: AppTheme.headingS.copyWith(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgInput,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusLog.isEmpty ? "Menunggu perintah..." : statusLog,
                                  style: TextStyle(
                                    color: _getStatusColor(statusLog),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (counter > 0)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: AppTheme.accentCardDecor(AppTheme.teal),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send, color: AppTheme.teal, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Total terkirim: ",
                                style: TextStyle(
                                  color: AppTheme.teal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "$counter",
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgInput,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: AppTheme.peach, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Auto send setiap 2 detik. Stop manual jika sudah cukup.",
                                style: AppTheme.bodyM,
                              ),
                            ),
                          ],
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

  Color _getStatusColor(String status) {
    if (status.contains('✅')) return AppTheme.mint;
    if (status.contains('❌')) return AppTheme.coral;
    if (status.contains('⚠️')) return AppTheme.peach;
    if (status.contains('▶️')) return AppTheme.mint;
    if (status.contains('⏹️')) return AppTheme.peach;
    return AppTheme.textPrimary;
  }
}
