import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String id;
  final String title;
  final String key;
  final String description;
  final String imageUrl;
  final List<String> tags;
  final String versionName;
  final int versionCode;
  final DateTime lastUpdated;
  final bool highlight;
  final String content;
  final ProjectSection sections;
  final bool isBeta;

  const Project({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.tags,
    required this.versionName,
    required this.versionCode,
    required this.lastUpdated,
    this.highlight = false,
    this.content = '',
    required this.sections,
    this.isBeta = false,
  });

  factory Project.fromFirestore(Map<String, dynamic> data, String id) {
    return Project(
      id: id,
      key: data['key'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image_url'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      versionName: data['version_name'] ?? '1.0.0',
      versionCode: data['version_code'] ?? 1,
      lastUpdated: data['last_updated'] != null
          ? DateTime.parse(data['last_updated'])
          : DateTime.now(),
      highlight: data['highlight'] ?? false,
      content: data['content'] ?? '',
      sections: data['sections'] != null
          ? ProjectSection.fromMap(data['sections'])
          : ProjectSection(),
      isBeta: data['is_beta'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'tags': tags,
      'version_name': versionName,
      'version_code': versionCode,
      'last_updated': lastUpdated.toIso8601String(),
      'highlight': highlight,
      'content': content,
      'sections': sections.toMap(),
      'is_beta': isBeta,
    };
  }

  @override
  List<Object?> get props => [
    id,
    key,
    title,
    description,
    imageUrl,
    tags,
    versionName,
    versionCode,
    lastUpdated,
    highlight,
    content,
    sections,
    isBeta,
  ];
}

class ProjectSection extends Equatable {
  final String? overview;
  final String? accessory;
  final String? guide;
  final String? printFile;
  final String? demo;
  final List<Firmware>? firmwares;

  const ProjectSection({
    this.overview,
    this.accessory,
    this.guide,
    this.printFile,
    this.demo,
    this.firmwares,
  });

  factory ProjectSection.fromMap(Map<String, dynamic> data) {
    return ProjectSection(
      overview: data['overview'],
      accessory: data['accessory'],
      guide: data['guide'],
      printFile: data['print_file'],
      demo: data['demo'],
      firmwares: data['firmware'] != null
          ? List<Firmware>.from(
              (data['firmware'] as List).map((item) => Firmware.fromMap(item)),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'overview': overview,
      'accessory': accessory,
      'guide': guide,
      'print_file': printFile,
      'demo': demo,
      'firmware': firmwares?.map((fw) => fw.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    overview,
    accessory,
    guide,
    printFile,
    demo,
    firmwares,
  ];
}

class Firmware extends Equatable {
  final String versionName;
  final String programUrl;
  final String changeLogs;
  final String? fileSystemUrl;
  final DateTime updatedAt;

  const Firmware({
    required this.versionName,
    required this.programUrl,
    required this.changeLogs,
    this.fileSystemUrl,
    required this.updatedAt,
  });

  factory Firmware.fromMap(Map<String, dynamic> data) {
    return Firmware(
      versionName: data['version_name'] ?? '',
      programUrl: data['program_url'] ?? '',
      changeLogs: data['change_logs'] ?? '',
      fileSystemUrl: data['file_system_url'],
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version_name': versionName,
      'program_url': programUrl,
      'change_logs': changeLogs,
      'file_system_url': fileSystemUrl,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    versionName,
    programUrl,
    changeLogs,
    fileSystemUrl,
    updatedAt,
  ];
}
