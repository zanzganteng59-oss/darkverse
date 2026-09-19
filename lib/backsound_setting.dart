import 'package:flutter/material.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'audio_service.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with WidgetsBindingObserver {
  final AudioService audioService = AudioService();

  bool isSoundOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    isSoundOn = audioService.isEnabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      audioService.pause();
    } else if (state == AppLifecycleState.resumed) {
      audioService.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: AppTheme.cardDecor().copyWith(
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: AppTheme.accentCardDecor(AppTheme.sky),
                        child: Text(
                          "Setting Apps",
                          style: AppTheme.headingM.copyWith(color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AppTheme.cardDecor(),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: AppTheme.bgDeep,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: const Icon(Icons.music_note, color: AppTheme.teal, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Background Sound",
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: isSoundOn,
                    activeColor: AppTheme.mint,
                    onChanged: (value) async {
                      setState(() {
                        isSoundOn = value;
                      });
                      await audioService.setEnabled(value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
