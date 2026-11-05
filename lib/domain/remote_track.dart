/// Stable metadata for a file beneath the fixed /AllMusic library root.
class RemoteTrack {
  const RemoteTrack({
    required this.path,
    required this.sizeBytes,
    this.artist,
    this.album,
    this.title,
    this.etag,
  });

  final String path;
  final int sizeBytes;
  final String? artist;
  final String? album;
  final String? title;
  final String? etag;

  String get fileName => path.split('/').last;

  String get displayTitle {
    final current = title?.trim();
    if (current != null && current.isNotEmpty) return current;
    final name = fileName;
    final extension = name.lastIndexOf('.');
    return extension > 0 ? name.substring(0, extension) : name;
  }

  String get displayArtist => artist == null || artist!.trim().isEmpty
      ? 'Неизвестный исполнитель'
      : artist!.trim();

  String get displayAlbum =>
      album == null || album!.trim().isEmpty ? 'Без альбома' : album!.trim();

  bool get isFlac => fileName.toLowerCase().endsWith('.flac');
  bool get isMp3 => fileName.toLowerCase().endsWith('.mp3');
}
