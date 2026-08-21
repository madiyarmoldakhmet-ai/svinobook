import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';

class PickedMedia {
  final Uint8List bytes;
  final String type;
  final String extension;

  const PickedMedia({required this.bytes, required this.type, required this.extension});
}

class MediaService {
  final StorageService _storage;
  final ImagePicker _picker = ImagePicker();

  MediaService({StorageService? storage}) : _storage = storage ?? StorageService();

  Future<PickedMedia?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final file = await _picker.pickImage(source: source, imageQuality: 78);
    if (file == null) return null;
    return PickedMedia(bytes: await file.readAsBytes(), type: 'image', extension: 'jpg');
  }

  Future<PickedMedia?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    final file = await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 5));
    if (file == null) return null;
    return PickedMedia(bytes: await file.readAsBytes(), type: 'video', extension: 'mp4');
  }

  Future<String> upload(PickedMedia media, String chatId, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final contentType = media.type == 'image' ? 'image/jpeg' : 'video/mp4';
    return (await _storage.uploadBytes(
      fileBytes: media.bytes,
      folder: 'messages/$chatId',
      fileName: '${timestamp}_$userId.${media.extension}',
      contentType: contentType,
    ))!;
  }
}