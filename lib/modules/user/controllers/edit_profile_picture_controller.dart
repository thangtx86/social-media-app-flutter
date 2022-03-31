import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:social_media_app/apis/providers/api_provider.dart';
import 'package:social_media_app/apis/services/auth_controller.dart';
import 'package:social_media_app/constants/strings.dart';
import 'package:social_media_app/helpers/utils.dart';

class EditProfilePictureController extends GetxController {
  static EditProfilePictureController get find => Get.find();

  final _auth = AuthController.find;

  final _apiProvider = ApiProvider(http.Client());

  final _pickedImage = Rxn<File>();

  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  File? get pickedImage => _pickedImage.value;

  Future<void> chooseImage() async {
    _pickedImage.value = await AppUtils.selectSingleImage();

    if (_pickedImage.value != null) {
      AppUtils.printLog(_pickedImage.value!.path);
      await _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    AppUtils.showLoadingDialog();
    _isLoading.value = true;
    update();

    try {
      final fileStream = http.ByteStream(pickedImage!.openRead());
      final fileLength = await pickedImage!.length();
      final multiPartFile = http.MultipartFile(
        "avatar",
        fileStream,
        fileLength,
        filename: pickedImage!.path,
      );

      final response = await _apiProvider.uploadProfilePicture(
        _auth.token,
        multiPartFile,
      );

      final responseDataFromStream = await http.Response.fromStream(response);
      final decodedData =
          jsonDecode(utf8.decode(responseDataFromStream.bodyBytes));

      AppUtils.printLog(decodedData);

      if (response.statusCode == 200) {
        AppUtils.closeDialog();
        await _auth.getProfileDetails();
        _isLoading.value = false;
        update();
      } else {
        AppUtils.closeDialog();
        _isLoading.value = false;
        update();
        AppUtils.showSnackBar(
          decodedData[StringValues.message],
          StringValues.error,
        );
      }
    } catch (err) {
      AppUtils.closeDialog();
      _isLoading.value = false;
      update();
      AppUtils.printLog(err);
      AppUtils.showSnackBar(
        '${StringValues.errorOccurred}: ${err.toString()}',
        StringValues.error,
      );
    }
  }

  Future<void> uploadProfilePicture() async {
    AppUtils.closeFocus();
    await _uploadProfilePicture();
  }
}