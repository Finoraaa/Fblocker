class UpdateInfo {
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final DateTime? publishedAt;
  final String downloadUrl;
  final String fileName;
  final int fileSizeBytes;
  final bool hasUpdate;

  const UpdateInfo({
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    this.publishedAt,
    required this.downloadUrl,
    required this.fileName,
    this.fileSizeBytes = 0,
    required this.hasUpdate,
  });

  String get formattedSize {
    if (fileSizeBytes <= 0) return '';
    final mb = fileSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
