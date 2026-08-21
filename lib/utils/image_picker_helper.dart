import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<Uint8List?> pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) {
        return await file.readAsBytes();
      }
    } catch (e) {
      developer.log('Error picking image: $e', name: 'ImagePickerHelper');
    }
    return null;
  }
}
