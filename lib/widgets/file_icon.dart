import 'package:flutter/material.dart';

class FileIcon extends StatelessWidget {
  final String name;
  final bool isDirectory;
  final bool isExpanded;
  final double size;

  const FileIcon({
    super.key,
    required this.name,
    required this.isDirectory,
    this.isExpanded = false,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (isDirectory) {
      return Icon(
        isExpanded ? Icons.folder_open : Icons.folder,
        color: const Color(0xFFE8A838),
        size: size,
      );
    }

    final ext = name.split('.').last.toLowerCase();
    IconData icon;
    Color color;

    switch (ext) {
      case 'v':
      case 'sv':
      case 'vh':
        icon = Icons.memory;
        color = const Color(0xFF58A6FF);
        break;
      case 'dart':
        icon = Icons.code;
        color = const Color(0xFF54C5F8);
        break;
      case 'py':
        icon = Icons.code;
        color = const Color(0xFF3572A5);
        break;
      case 'md':
        icon = Icons.description;
        color = const Color(0xFF6A9FB5);
        break;
      case 'json':
      case 'yaml':
      case 'yml':
        icon = Icons.data_object;
        color = const Color(0xFFF0DB4F);
        break;
      case 'html':
        icon = Icons.web;
        color = const Color(0xFFE44D26);
        break;
      case 'vcd':
        icon = Icons.show_chart;
        color = const Color(0xFF3FB950);
        break;
      case 'txt':
        icon = Icons.article;
        color = Colors.grey;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: size);
  }
}

String languageForFile(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  switch (ext) {
    case 'v':
    case 'sv':
    case 'vh':
      return 'verilog';
    case 'dart':
      return 'dart';
    case 'py':
      return 'python';
    case 'js':
    case 'ts':
      return 'javascript';
    case 'json':
      return 'json';
    case 'yaml':
    case 'yml':
      return 'yaml';
    case 'html':
      return 'html';
    case 'css':
      return 'css';
    case 'sh':
    case 'bash':
      return 'bash';
    case 'c':
    case 'h':
      return 'c';
    case 'cpp':
    case 'hpp':
      return 'cpp';
    default:
      return 'plaintext';
  }
}

bool isTextFile(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  const textExts = {
    'v', 'sv', 'vh', 'dart', 'py', 'js', 'ts', 'json', 'yaml', 'yml',
    'html', 'css', 'sh', 'bash', 'c', 'h', 'cpp', 'hpp', 'md', 'txt',
    'vcd', 'tcl', 'sdc', 'xdc', 'do', 'f', 'gitignore', 'gitattributes',
  };
  return textExts.contains(ext) || !filename.contains('.');
}
