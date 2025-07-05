import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalFileHelper {
  /// Save a picked image file to local app directory
  static Future<String> saveImageToLocal(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(imageFile.path);
    final savedImage = await imageFile.copy('${appDir.path}/$fileName');
    return savedImage.path;
  }
}
