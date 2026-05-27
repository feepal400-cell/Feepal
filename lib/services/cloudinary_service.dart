import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class CloudinaryService {
  /// Picks and uploads an image to Cloudinary using a dynamic upload preset.
  /// Returns the secure URL if successful, otherwise null.
  static Future<String?> pickAndUploadImage({required String uploadPreset}) async {
    try {
      // 1. Let the Admin select a single image file
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint("❌ User cancelled the picker");
        return null;
      }

      PlatformFile file = result.files.first;
      debugPrint("📂 File selected: ${file.name}");

      // 2. Prepare Cloudinary Request using your specific credentials
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dhx7ckjpe/image/upload",
      );
      var request = http.MultipartRequest("POST", uri);

      // Dynamic upload preset
      request.fields['upload_preset'] = uploadPreset;

      // Add the file (Android)
      if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!),
        );
      } else if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      }

      // 3. Execute Upload to Cloudinary
      debugPrint("🚀 Uploading to Cloudinary with preset: $uploadPreset...");
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 4. Extract secure_url
        var jsonResponse = jsonDecode(responseData);
        String secureUrl = jsonResponse['secure_url'];
        debugPrint("✅ Cloudinary URL: $secureUrl");
        return secureUrl;
      } else {
        debugPrint("❌ Cloudinary Upload Failed: $responseData");
        return null;
      }
    } catch (e) {
      debugPrint("🚨 Error in pickAndUploadImage: $e");
      return null;
    }
  }

  /// Uploads a pre-selected PlatformFile to Cloudinary.
  /// Returns the secure URL if successful, otherwise null.
  static Future<String?> uploadFile(PlatformFile file, {required String uploadPreset}) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/dhx7ckjpe/image/upload");
      var request = http.MultipartRequest("POST", uri);

      request.fields['upload_preset'] = uploadPreset;

      if (file.path != null) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path!));
      } else if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
        );
      }

      debugPrint("🚀 Uploading to Cloudinary with preset: $uploadPreset...");
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseData);
        String secureUrl = jsonResponse['secure_url'];
        debugPrint("✅ Cloudinary URL: $secureUrl");
        return secureUrl;
      } else {
        debugPrint("❌ Cloudinary Upload Failed: $responseData");
        return null;
      }
    } catch (e) {
      debugPrint("🚨 Error in uploadFile: $e");
      return null;
    }
  }

  /// Uploads a pre-selected dart:io File to Cloudinary.
  /// Returns the secure URL if successful, otherwise null.
  static Future<String?> uploadDartIoFile(File file, {required String uploadPreset}) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/dhx7ckjpe/image/upload");
      var request = http.MultipartRequest("POST", uri);

      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      debugPrint("🚀 Uploading dart:io File to Cloudinary with preset: $uploadPreset...");
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseData);
        String secureUrl = jsonResponse['secure_url'];
        debugPrint("✅ Cloudinary URL: $secureUrl");
        return secureUrl;
      } else {
        debugPrint("❌ Cloudinary Upload Failed: $responseData");
        return null;
      }
    } catch (e) {
      debugPrint("🚨 Error in uploadDartIoFile: $e");
      return null;
    }
  }
}
