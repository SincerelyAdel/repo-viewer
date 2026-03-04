import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github-dark.dart';
import '../models/repo_item.dart';
import '../services/github_service.dart';
import '../services/claude_service.dart';
import '../services/prefs_service.dart';
import '../widgets/file_icon.dart';

class FileViewerScreen extends StatefulWidget {
  final RepoItem item;
  final String owner;
  final String repo;
  final GitHubService github;

  const FileViewerScreen({
    super.key,
    required this.item,
    required this.owner,
    required this.repo,
    required this.github,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  String? _content;
  String? _error;
  bool _loading = true;
  String? _explanation;
  bool _explaining = false;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final content = await widget.github
          .getFileContent(widget.owner, widget.repo, widget.item.path);
      setState(() {
        _content = content;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _explain() async {
    final key = await PrefsService.getClaudeKey();
    if (key == null || key.isEmpty) {
      _showSnack('Add your Claude API key in Settings first');
      return;
    }
    setState(() => _explaining = true);
    try {
      final service = ClaudeService(apiKey: key);
      final result =
          await service.explainFile(widget.item.name, _content ?? '');
      setState(() {
        _explanation = result;
        _explaining = false;
      });
    } catch (e) {
      setState(() => _explaining = false);
      _showSnack('Claude error: $e');
    }
  }

  void _copy() {
    if (_content != null) {
      Clipboard.setData(ClipboardData(text: _content!));
      _showSnack('Copied to clipboard');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final lang = languageForFile(widget.item.name);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Row(children: [
          FileIcon(name: widget.item.name, isDirectory: false, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.item.name,
              style: const TextStyle(
                  color: Color(0xFFC9D1D9),
                  fontFamily: 'monospace',
                  fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        iconTheme: const IconThemeData(color: Color(0xFFC9D1D9)),
        actions: [
          if (_content != null)
            IconButton(
              icon: const Icon(Icons.copy, color: Color(0xFF8B949E)),
              tooltip: 'Copy',
              onPressed: _copy,
            ),
          if (_content != null && lang == 'verilog')
            TextButton.icon(
              icon: _explaining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF58A6FF)))
                  : const Icon(Icons.auto_awesome,
                      color: Color(0xFF58A6FF), size: 18),
              label: const Text('Explain',
                  style: TextStyle(color: Color(0xFF58A6FF))),
              onPressed: _explaining ? null : _explain,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    if (_explanation != null) _buildExplanation(),
                    Expanded(child: _buildCode(lang)),
                  ],
                ),
    );
  }

  Widget _buildExplanation() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF58A6FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF58A6FF), size: 16),
            const SizedBox(width: 6),
            const Text('Claude Explanation',
                style: TextStyle(
                    color: Color(0xFF58A6FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close,
                  color: Color(0xFF8B949E), size: 16),
              onPressed: () => setState(() => _explanation = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 8),
          Text(_explanation!,
              style: const TextStyle(
                  color: Color(0xFFC9D1D9), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCode(String lang) {
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: HighlightView(
            _content ?? '',
            language: lang,
            theme: githubDarkTheme,
            padding: const EdgeInsets.all(16),
            textStyle:
                const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.5),
          ),
        ),
      ),
    );
  }
}
