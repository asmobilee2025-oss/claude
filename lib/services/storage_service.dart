import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';

class ImageTooLargeException implements Exception {}

/// Uploads user images under paths that storage.rules scope to the owner.
class StorageService {
  StorageService(this._storage);
  final FirebaseStorage _storage;
  static const _uuid = Uuid();

  Future<String> uploadListingImage(String uid, XFile file) => _upload('listings/$uid/${_uuid.v4()}', file);

  Future<String> uploadAvatar(String uid, XFile file) => _upload('avatars/$uid/${_uuid.v4()}', file);

  Future<String> _upload(String path, XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > AppConstants.maxImageBytes) throw ImageTooLargeException();
    final mime = file.mimeType ?? _guessMime(file.name);
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: mime, cacheControl: 'public,max-age=604800'));
    return ref.getDownloadURL();
  }

  /// Best-effort cleanup; ignored if the file is already gone or not ours.
  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }

  static String _guessMime(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
