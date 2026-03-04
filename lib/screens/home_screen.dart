import 'package:flutter/material.dart';
import '../services/github_service.dart';
import '../services/prefs_service.dart';
import 'repo_browser_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<String> _recentRepos = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
    // Pre-fill with Adel's repo
    _urlCtrl.text = 'https://github.com/SincerelyAdel/RTL';
  }

  Future<void> _loadRecent() async {
    final repos = await PrefsService.getRecentRepos();
    setState(() => _recentRepos = repos);
  }

  Future<void> _open(String input) async {
    final parsed = GitHubService.parseRepoUrl(input);
    if (parsed == null) {
      setState(() => _error = 'Invalid GitHub URL or format');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await PrefsService.getGithubToken();
      final github = GitHubService(token: token);
      // Verify the repo exists
      await github.getRepoInfo(parsed['owner']!, parsed['repo']!);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RepoBrowserScreen(
            owner: parsed['owner']!,
            repo: parsed['repo']!,
            token: token,
          ),
        ),
      ).then((_) => _loadRecent());
    } catch (e) {
      setState(() => _error = 'Could not open repo: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final contentWidth = isTablet ? 560.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF58A6FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.code,
                color: Color(0xFF58A6FF), size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'RepoViewer',
            style: TextStyle(
                color: Color(0xFFC9D1D9),
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF3FB950).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: const Color(0xFF3FB950).withOpacity(0.4)),
            ),
            child: const Text('Claude',
                style: TextStyle(
                    color: Color(0xFF3FB950),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings,
                color: Color(0xFF8B949E)),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SettingsScreen()),
            ).then((_) => _loadRecent()),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: contentWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 0 : 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Open Repository',
                  style: TextStyle(
                      color: Color(0xFFC9D1D9),
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter a GitHub repository URL or owner/repo',
                  style: TextStyle(
                      color: Color(0xFF8B949E), fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _urlCtrl,
                      style: const TextStyle(
                          color: Color(0xFFC9D1D9),
                          fontFamily: 'monospace',
                          fontSize: 14),
                      onSubmitted: (v) => _open(v),
                      decoration: InputDecoration(
                        hintText:
                            'https://github.com/owner/repo',
                        hintStyle: const TextStyle(
                            color: Color(0xFF484F58)),
                        prefixIcon: const Icon(Icons.link,
                            color: Color(0xFF8B949E)),
                        filled: true,
                        fillColor: const Color(0xFF161B22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF30363D)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF30363D)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF58A6FF)),
                        ),
                        errorText: _error,
                        errorStyle: const TextStyle(
                            color: Color(0xFFDA3633)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () => _open(_urlCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF238636),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Text('Open',
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                  ),
                ]),
                if (_recentRepos.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Recent',
                    style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._recentRepos.take(5).map((r) => Card(
                        color: const Color(0xFF161B22),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                              color: Color(0xFF30363D)),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.history,
                              color: Color(0xFF8B949E), size: 18),
                          title: Text(
                            r,
                            style: const TextStyle(
                                color: Color(0xFF58A6FF),
                                fontFamily: 'monospace',
                                fontSize: 13),
                          ),
                          trailing: const Icon(Icons.arrow_forward,
                              color: Color(0xFF484F58), size: 16),
                          dense: true,
                          onTap: () {
                            _urlCtrl.text =
                                'https://github.com/$r';
                            _open('https://github.com/$r');
                          },
                        ),
                      )),
                ],
                const Spacer(),
                _buildFeatureRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip(Icons.folder_open, 'Browse files'),
        const SizedBox(width: 12),
        _chip(Icons.download, 'Download ZIP'),
        const SizedBox(width: 12),
        _chip(Icons.auto_awesome, 'AI Reports'),
        const SizedBox(width: 12),
        _chip(Icons.memory, 'Verilog HDL'),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFF8B949E)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8B949E), fontSize: 12)),
      ]),
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }
}
