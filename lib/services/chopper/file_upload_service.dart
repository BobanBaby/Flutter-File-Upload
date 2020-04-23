import "dart:async";
import 'package:chopper/chopper.dart';
import 'package:http/http.dart' show MultipartFile;
// this is necessary for the generated code to find your class
part "file_upload_service.chopper.dart";

@ChopperApi()
abstract class FileUploadService extends ChopperService {
  // helper methods that help you instanciate your service
  static FileUploadService create(String url) {
    final client = ChopperClient(
        baseUrl: url,
        services: [_$FileUploadService()],
        interceptors: [HttpLoggingInterceptor() /*,CurlInterceptor()*/]);
    return _$FileUploadService(client);
  }

  @Post()
  @multipart
  Future<Response> fileUpload(@PartFile() MultipartFile file);
}
