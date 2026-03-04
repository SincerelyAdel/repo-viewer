import 'package:flutter/material.dart';
import '../services/prefs_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _claudeCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  bool _claudeVisible = false;
  bool _githubVisible = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final claude = await PrefsService.getClaudeKey();
    final github = await PrefsService.getGithubToken();
    setState(() {
      _claudeCtrl.text = claude ?? '';
      _githubCtrl.text = github ?? '';
    });
  }

  Future<void> _save() async {
    await PrefsService.setClaudeKey(_claudeCtrl.text.trim());
    await PrefsService.setGithubToken(_githubCtrl.text.trim());
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Settings',
            style: TextStyle(color: Color(0xFFC9D1D9))),
        iconTheme: const IconThemeData(color: Color(0xFFC9D1D9)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Claude API Key'),
            const SizedBox(height: 8),
            _buildKeyField(
              controller: _claudeCtrl,
              hint: 'sk-ant-api03-...',
              visible: _claudeVisible,
              onToggle: () =>
                  setState(() => _claudeVisible = !_claudeVisible),
            ),
            const SizedBox(height: 8),
            _hint(
                'Required for AI-powered report generation and file explanations.'),
            const SizedBox(height: 28),
            _sectionTitle('GitHub Personal Access Token'),
            const SizedBox(height: 8),
            _buildKeyField(
              controller: _githubCtrl,
              hint: 'github_pat_... (optional for public repos)',
              visible: _githubVisible,
              onToggle: () =>
                  setState(() => _githubVisible = !_githubVisible),
            ),
            const SizedBox(height: 8),
            _hint(
                'Optional. Required for private repos or to avoid rate limits. Use a fine-grained token with Contents: Read-only.'),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238636),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _saved ? '✓ Saved' : 'Save',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _sectionTitle('Recent Repos'),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: PrefsService.getRecentRepos(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.isEmpty) {
                  return _hint('No recent repos.');
                }
                return Column(
                  children: snap.data!
                      .map((r) => ListTile(
                            title: Text(r,
                                style: const TextStyle(
                                    color: Color(0xFF58A6FF),
                                    fontFamily: 'monospace')),
                            trailing: const Icon(Icons.open_in_new,
                                color: Color(0xFF8B949E), size: 18),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await PrefsService.clearRecentRepos();
                setState(() {});
              },
              child: const Text('Clear recent repos',
                  style: TextStyle(color: Color(0xFFDA3633))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(
          color: Color(0xFFC9D1D9),
          fontSize: 16,
          fontWeight: FontWeight.bold));

  Widget _hint(String text) => Text(text,
      style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13));

  Widget _buildKeyField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      style: const TextStyle(
          color: Color(0xFFC9D1D9), fontFamily: 'monospace', fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF484F58)),
        filled: true,
        fillColor: const Color(0xFF161B22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF58A6FF)),
        ),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF8B949E)),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _claudeCtrl.dispose();
    _githubCtrl.dispose();
    super.dispose();
  }
}
