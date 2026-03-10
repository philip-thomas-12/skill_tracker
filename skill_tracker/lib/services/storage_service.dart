// import 'dart:io'; // Removed for Web compatibility
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:file_picker/file_picker.dart'; // Will be used in UI

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // uploadFile removed to depend only on bytes (Web compatible)

  // Web support if needed (File Picker returns bytes for web)
  Future<String?> uploadBytes(List<int> bytes, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      // Simple putData for bytes
      UploadTask uploadTask = ref.putData(Uint8List.fromList(bytes)); 
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading bytes: $e");
      return null;
    }
  }
}
