import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:svinobook/services/media_service.dart';
import 'package:svinobook/services/storage_service.dart';

class _ImagePickerMock extends Mock implements ImagePicker {}

class _StorageServiceFake extends StorageService {
  Uint8List? uploadedBytes;
  String? uploadedFolder;
  String? uploadedFileName;
  String? uploadedContentType;

  @override
  Future<String?> uploadBytes({
    required Uint8List fileBytes,
    required String folder,
    required String fileName,
    required String contentType,
  }) async {
    uploadedBytes = fileBytes;
    uploadedFolder = folder;
    uploadedFileName = fileName;
    uploadedContentType = contentType;
    return 'https://example.test/$fileName';
  }
}

void main() {
  test('picks an image and uploads it with image metadata', () async {
    final picker = _ImagePickerMock();
    final storage = _StorageServiceFake();
    final imageBytes = Uint8List.fromList([1, 2, 3]);
    when(() => picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: any(named: 'imageQuality'),
        )).thenAnswer((_) async => XFile.fromData(imageBytes, name: 'photo.png'));

    final service = MediaService(storage: storage, picker: picker);
    final media = await service.pickImage();
    final url = await service.upload(media!, 'chat-1', 'user-1');

    expect(media.type, 'image');
    expect(media.extension, 'jpg');
    expect(url, startsWith('https://example.test/'));
    expect(storage.uploadedBytes, imageBytes);
    expect(storage.uploadedFolder, 'messages/chat-1');
    expect(storage.uploadedContentType, 'image/jpeg');
  });

  test('returns null when the picker is cancelled', () async {
    final picker = _ImagePickerMock();
    when(() => picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: any(named: 'maxDuration'),
        )).thenAnswer((_) async => null);

    final media = await MediaService(picker: picker, storage: _StorageServiceFake()).pickVideo();

    expect(media, isNull);
  });
}
