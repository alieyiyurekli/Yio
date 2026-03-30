/// Model for media items in the recipe gallery
/// Supports both images and videos
class GalleryMediaModel {
  final MediaType type;
  final String url;
  final String? thumbnail;

  const GalleryMediaModel({
    required this.type,
    required this.url,
    this.thumbnail,
  });

  /// Create an image media item
  factory GalleryMediaModel.image(String url) {
    return GalleryMediaModel(
      type: MediaType.image,
      url: url,
    );
  }

  /// Create a video media item
  factory GalleryMediaModel.video(String url, {String? thumbnail}) {
    return GalleryMediaModel(
      type: MediaType.video,
      url: url,
      thumbnail: thumbnail,
    );
  }

  /// Create from a local file path
  factory GalleryMediaModel.fromFile(String filePath, MediaType type) {
    return GalleryMediaModel(
      type: type,
      url: filePath,
    );
  }

  /// Check if this is a local file
  bool get isLocalFile {
    return url.startsWith('/') || url.startsWith('file://');
  }

  /// Check if this is a network URL
  bool get isNetworkUrl {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  String toString() {
    return 'GalleryMediaModel(type: $type, url: $url, thumbnail: $thumbnail)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryMediaModel &&
        other.type == type &&
        other.url == url &&
        other.thumbnail == thumbnail;
  }

  @override
  int get hashCode => type.hashCode ^ url.hashCode ^ thumbnail.hashCode;
}

/// Enum representing the type of media
enum MediaType {
  image,
  video,
}

/// Extension on MediaType for helper methods
extension MediaTypeExtension on MediaType {
  bool get isImage => this == MediaType.image;
  bool get isVideo => this == MediaType.video;
}
