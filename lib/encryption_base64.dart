import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:darkverse/theme/app_theme.dart';

class EncryptionRavenClawx extends StatefulWidget {
  const EncryptionRavenClawx({super.key});

  @override
  State<EncryptionRavenClawx> createState() => _EncryptionRavenClawxState();
}

class _EncryptionRavenClawxState extends State<EncryptionRavenClawx> {
  String fileType = 'js';
  String inputText = '';
  String outputText = '';

  String encrypt(String text) => base64Encode(utf8.encode(text));
  String decrypt(String text) => utf8.decode(base64Decode(text));

  Future<void> autoDownload(String data) async {
    final dir = await getExternalStorageDirectory();
    final fileName = "RavenClawx_${DateTime.now().millisecondsSinceEpoch}.$fileType";
    final file = File("${dir!.path}/$fileName");
    await file.writeAsString(data);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppTheme.coral, content: Text("Saved: $fileName")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.enhanced_encryption, color: AppTheme.coral),
        title: Text("Encryption Prime Vision", style: AppTheme.headingM),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: AppTheme.inputDecor(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: AppTheme.bgCard,
                  value: fileType,
                  style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'js', child: Text("JavaScript (.js)")),
                    DropdownMenuItem(value: 'html', child: Text("HTML (.html)")),
                  ],
                  onChanged: (v) => setState(() => fileType = v!),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // INPUT
            Expanded(
              child: Container(
                decoration: AppTheme.inputDecor(),
                child: TextField(
                  maxLines: null,
                  expands: true,
                  style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: "Input Source",
                    labelStyle: AppTheme.bodyM.copyWith(color: AppTheme.coral),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (v) => inputText = v,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: AppTheme.primaryButton(AppTheme.coral),
                    icon: const Icon(Icons.enhanced_encryption),
                    label: const Text("Encrypt + Download"),
                    onPressed: () {
                      outputText = encrypt(inputText);
                      autoDownload(outputText);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: AppTheme.primaryButton(AppTheme.coral),
                    icon: const Icon(Icons.lock_open),
                    label: const Text("Decrypt"),
                    onPressed: () {
                      outputText = decrypt(inputText);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // OUTPUT
            Expanded(
              child: Container(
                decoration: AppTheme.inputDecor(),
                child: TextField(
                  readOnly: true,
                  maxLines: null,
                  expands: true,
                  style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: "Output Result",
                    labelStyle: AppTheme.bodyM.copyWith(color: AppTheme.coral),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  controller: TextEditingController(text: outputText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
