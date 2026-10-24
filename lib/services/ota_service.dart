import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/update_info.dart';

class OtaService extends ChangeNotifier {
  static const String currentAppVersion = '1.0.0';
  static const String repoApiUrl = 'https://api.github.com/repos/Finoraaa/Fblocker/releases/latest';

  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String _statusMessage = '';
  UpdateInfo? _latestRelease;

  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  int get receivedBytes => _receivedBytes;
  int get totalBytes => _totalBytes;
  String get statusMessage => _statusMessage;
  UpdateInfo? get latestRelease => _latestRelease;

  String _cleanVersion(String tag) {
    return tag.replaceFirst(RegExp(r'^[vV]'), '').trim();
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final lParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      while (lParts.length < 3) {
        lParts.add(0);
      }
      while (cParts.length < 3) {
        cParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (lParts[i] > cParts[i]) return true;
        if (lParts[i] < cParts[i]) return false;
      }
      return false;
    } catch (_) {
      return latest != current;
    }
  }

  Future<UpdateInfo?> checkForUpdates() async {
    _isChecking = true;
    _statusMessage = 'Güncellemeler kontrol ediliyor...';
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(repoApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Finora-Fblocker-App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawTag = data['tag_name'] as String? ?? 'v1.0.0';
        final cleanTag = _cleanVersion(rawTag);
        final releaseName = data['name'] as String? ?? 'Finora Fblocker $rawTag';
        final body = data['body'] as String? ?? 'Yeni özellikler ve hata düzeltmeleri.';
        final publishedStr = data['published_at'] as String?;
        final publishedAt = publishedStr != null ? DateTime.tryParse(publishedStr) : null;
        final assets = (data['assets'] as List<dynamic>?) ?? [];

        String matchedDownloadUrl = '';
        String matchedFileName = '';
        int matchedSize = 0;

        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          final url = asset['browser_download_url'] as String? ?? '';
          final size = (asset['size'] as int?) ?? 0;

          if (!kIsWeb) {
            if (Platform.isLinux && (name.endsWith('.AppImage') || name.endsWith('.deb'))) {
              matchedDownloadUrl = url;
              matchedFileName = name;
              matchedSize = size;
              if (name.endsWith('.AppImage')) break; // Prefer AppImage
            } else if (Platform.isWindows && (name.endsWith('.exe') || name.endsWith('.zip'))) {
              matchedDownloadUrl = url;
              matchedFileName = name;
              matchedSize = size;
              if (name.endsWith('.exe')) break;
            } else if (Platform.isAndroid && name.endsWith('.apk')) {
              matchedDownloadUrl = url;
              matchedFileName = name;
              matchedSize = size;
              break;
            } else if (Platform.isMacOS && (name.endsWith('.dmg') || name.endsWith('.zip'))) {
              matchedDownloadUrl = url;
              matchedFileName = name;
              matchedSize = size;
              if (name.endsWith('.dmg')) break;
            } else if (Platform.isIOS && name.endsWith('.ipa')) {
              matchedDownloadUrl = url;
              matchedFileName = name;
              matchedSize = size;
              break;
            }
          }
        }

        final hasNewer = _isNewerVersion(cleanTag, currentAppVersion);

        _latestRelease = UpdateInfo(
          latestVersion: cleanTag,
          releaseName: releaseName,
          releaseNotes: body,
          publishedAt: publishedAt,
          downloadUrl: matchedDownloadUrl,
          fileName: matchedFileName.isNotEmpty ? matchedFileName : 'fblocker-update',
          fileSizeBytes: matchedSize,
          hasUpdate: hasNewer,
        );

        _statusMessage = hasNewer
            ? 'Yeni sürüm mevcut: v$cleanTag'
            : 'Uygulamanız güncel (v$currentAppVersion)';
      } else {
        _statusMessage = 'Güncelleme sunucusuna ulaşılamadı (${response.statusCode})';
      }
    } catch (e) {
      _statusMessage = 'Güncelleme kontrolü başarısız: $e';
    } finally {
      _isChecking = false;
      notifyListeners();
    }

    return _latestRelease;
  }

  Future<File?> downloadAndInstallUpdate() async {
    if (_latestRelease == null || _latestRelease!.downloadUrl.isEmpty) {
      _statusMessage = 'İndirilebilir paket bulunamadı.';
      notifyListeners();
      return null;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    _receivedBytes = 0;
    _totalBytes = _latestRelease!.fileSizeBytes;
    _statusMessage = 'İndiriliyor: ${_latestRelease!.fileName}...';
    notifyListeners();

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_latestRelease!.downloadUrl));
      request.headers['User-Agent'] = 'Finora-Fblocker-App';

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? _totalBytes;
      _totalBytes = contentLength;

      final dir = await getTemporaryDirectory();
      final targetFile = File('${dir.path}/${_latestRelease!.fileName}');
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final sink = targetFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        _receivedBytes += chunk.length;
        if (_totalBytes > 0) {
          _downloadProgress = _receivedBytes / _totalBytes;
        }
        notifyListeners();
      }

      await sink.flush();
      await sink.close();

      _statusMessage = 'İndirme tamamlandı: ${targetFile.path}';
      notifyListeners();

      // Launch or install depending on OS
      if (!kIsWeb) {
        if (Platform.isLinux && targetFile.path.endsWith('.AppImage')) {
          await Process.run('chmod', ['+x', targetFile.path]);
          _statusMessage = 'Güncelleme hazır. Başlatılıyor...';
          notifyListeners();
          await Process.start(targetFile.path, []);
        } else if (Platform.isWindows && targetFile.path.endsWith('.exe')) {
          await Process.start(targetFile.path, []);
        }
      }

      return targetFile;
    } catch (e) {
      _statusMessage = 'İndirme hatası: $e';
      return null;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }
}
