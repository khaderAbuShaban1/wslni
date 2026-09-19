import 'dart:io';

import '../models/user_model.dart';
import 'api_client.dart';

class ProfileService {
  ProfileService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<AppUser> fetchMe() async {
    final result = await _api.get('customers/me');
    return AppUser.fromJson(result['user'] as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile({
    required String name,
    required String phone,
  }) async {
    final result = await _api.patch('customers/me', {
      'name': name,
      'phone': phone,
    });
    return AppUser.fromJson(result['user'] as Map<String, dynamic>);
  }

  /// Returns the stored path of the uploaded photo.
  Future<String> uploadAvatar(File image) async {
    final result = await _api.postMultipart(
      'me/avatar',
      fields: const {},
      fileField: 'avatar',
      file: image,
    );
    return result['avatar_path'].toString();
  }

  Future<void> removeAvatar() => _api.delete('me/avatar');
}
