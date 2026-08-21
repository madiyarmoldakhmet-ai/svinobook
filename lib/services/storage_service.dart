import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage({
    required Uint8List fileBytes,
    required String folder,
    required String fileName,
  }) async {
    try {
      final Reference ref = _storage.ref().child(folder).child(fileName);
      final UploadTask uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Image upload failed. Check Firebase Storage rules: $e');
    }
  }
}
