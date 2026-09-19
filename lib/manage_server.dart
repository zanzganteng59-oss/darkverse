import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api.dart';
import 'package:darkverse/theme/app_theme.dart';

class ManageServerPage extends StatefulWidget {
  final String keyToken;
  const ManageServerPage({super.key, required this.keyToken});

  @override
  State<ManageServerPage> createState() => _ManageServerPageState();
}

class _ManageServerPageState extends State<ManageServerPage> {
  List<Map<String, dynamic>> vpsList = [];
  bool isLoading = false;

  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVpsList();
  }

  Future<void> _fetchVpsList() async {
    setState(() => isLoading = true);
    final uri = Uri.parse('${ApiConfig.baseUrl}/myServer?key=${widget.keyToken}');
    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      setState(() {
        vpsList = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {
      _showError("Gagal mengambil data VPS.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _addVps() async {
    final host = _hostController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    if (host.isEmpty || user.isEmpty || pass.isEmpty) {
      _showError("Isi semua field terlebih dahulu.");
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/addServer');
    try {
      final res = await http.post(uri, body: {
        'key': widget.keyToken,
        'host': host,
        'username': user,
        'password': pass,
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _hostController.clear();
        _userController.clear();
        _passController.clear();
        _fetchVpsList();
      } else {
        _showError(data['error'] ?? 'Gagal menambah VPS');
      }
    } catch (_) {
      _showError("Gagal terhubung ke server.");
    }
  }

  Future<void> _deleteVps(String host) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/delServer');
    try {
      final res = await http.post(uri, body: {
        'key': widget.keyToken,
        'host': host,
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _fetchVpsList();
      } else {
        _showError("Gagal menghapus VPS.");
      }
    } catch (_) {
      _showError("Gagal menghubungi server.");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Text("Error", style: AppTheme.headingM),
        content: Text(msg, style: AppTheme.bodyM),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Text("Tambah VPS", style: AppTheme.headingM),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput("IP VPS", _hostController),
            _buildInput("Username", _userController),
            _buildInput("Password", _passController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("BATAL", style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addVps();
            },
            style: AppTheme.primaryButton(AppTheme.teal),
            child: const Text("TAMBAH", style: TextStyle(color: AppTheme.bgDeep)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.teal),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.borderSubtle),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.teal),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          filled: true,
          fillColor: AppTheme.bgInput,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("My VPS List", style: AppTheme.headingM),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppTheme.textPrimary),
                    onPressed: _showAddDialog,
                  )
                ],
              ),
              const Divider(color: AppTheme.borderSubtle),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.lavender))
                    : ListView.builder(
                  itemCount: vpsList.length,
                  itemBuilder: (context, index) {
                    final vps = vpsList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: AppTheme.cardDecor(),
                      child: ListTile(
                        title: Text("${vps['host']}", style: const TextStyle(color: AppTheme.textPrimary)),
                        subtitle: Text("User: ${vps['username']}", style: const TextStyle(color: AppTheme.textSecondary)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.lavender),
                          onPressed: () => _deleteVps(vps['host']),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
