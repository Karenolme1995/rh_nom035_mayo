import 'package:image_picker/image_picker.dart';
import 'dart:io';

File? selectedImage;

Future<void> pickImage() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    setState(() {
      selectedImage = File(image.path);
    });
  }
}