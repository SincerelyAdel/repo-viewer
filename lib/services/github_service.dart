import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/repo_item.dart';

class GitHubService {
  static const String _baseUrl = 'https://api.github.com';
  final String? token;

  GitHubService({this.token});

  Map<String, String> get _headers => {
        'Accept': 'application/vnd.github.v3+json',
        if (token != null && token!.isNotEmpty)
          'Authorization': 'token $token',
      };

  Future<RepoInfo> getRepoInfo(String owner, String repo) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$owner/$repo'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return RepoInfo.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load repo: ${response.statusCode}');
  }

  Future<List<RepoItem>> getContents(
      String owner, String repo, String path) async {
    final encodedPath = path.isEmpty ? '' : '/$path';
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$owner/$repo/contents$encodedPath'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final items = data.map((e) => RepoItem.fromJson(e)).toList();
      // Sort: directories first, then files, both alphabetically
      items.sort((a, b) {
        if (a.isDirectory && b.isFile) return -1;
        if (a.isFile && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return items;
    }
    throw Exception('Failed to load contents: ${response.statusCode}');
  }

  Future<String> getFileContent(String owner, String repo, String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$owner/$repo/contents/$path'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final encoded = data['content'] as String;
      return utf8.decode(base64.decode(encoded.replaceAll('\n', '')));
    }
    throw Exception('Failed to load file: ${response.statusCode}');
  }

  Future<List<RepoItem>> getAllVerilogFiles(
      String owner, String repo) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/repos/$owner/$repo/git/trees/HEAD?recursive=1'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tree = data['tree'] as List<dynamic>;
      return tree
          .where((e) =>
              e['type'] == 'blob' &&
              (e['path'].toString().endsWith('.v') ||
                  e['path'].toString().endsWith('.sv') ||
                  e['path'].toString().endsWith('.vh')))
          .map((e) => RepoItem(
                name: e['path'].toString().split('/').last,
                path: e['path'],
                type: 'file',
                size: e['size'],
                sha: e['sha'],
              ))
          .toList();
    }
    throw Exception('Failed to fetch tree: ${response.statusCode}');
  }

  /// Parses "https://github.com/owner/repo" or "owner/repo"
  static Map<String, String>? parseRepoUrl(String input) {
    input = input.trim();
    final githubRegex =
        RegExp(r'github\.com[/:]([^/]+)/([^/\s]+?)(?:\.git)?(?:/.*)?$');
    final match = githubRegex.firstMatch(input);
    if (match != null) {
      return {'owner': match.group(1)!, 'repo': match.group(2)!};
    }
    final shortRegex = RegExp(r'^([^/]+)/([^/]+)$');
    final shortMatch = shortRegex.firstMatch(input);
    if (shortMatch != null) {
      return {'owner': shortMatch.group(1)!, 'repo': shortMatch.group(2)!};
    }
    return null;
  }
}
