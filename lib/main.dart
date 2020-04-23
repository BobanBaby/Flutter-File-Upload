import 'dart:io';

import 'package:dio/dio.dart' as DioLib;
import 'package:floating_action_row/floating_action_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:math';
import 'package:logging/logging.dart';

import 'services/chopper/file_upload_service.dart';

void main() {
  _setupLogging();
  runApp(MyApp());
}

// Logger is a package from the Dart team. While you can just simply use print()
// to easily print to the debug console, using a fully-blown logger allows you to
// easily set up multiple logging "levels" - e.g. INFO, WARNING, ERROR.

// Chopper already uses the Logger package. Printing the logs to the console requires
// the following setup.
void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter File Upload Example',
      home: StartPage(),
    );
  }
}

class StartPage extends StatelessWidget {
  void switchScreen(str, context) => Navigator.push(
      context, MaterialPageRoute(builder: (context) => UploadPage(url: str)));
  @override
  Widget build(context) {
    TextEditingController controller = TextEditingController();
    return Scaffold(
        appBar: AppBar(title: Text('Flutter File Upload Example')),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Text(
                  "Insert the URL that will receive the Multipart POST request (including the starting http://)",
                  style: Theme.of(context).textTheme.headline),
              TextField(
                controller: controller,
                onSubmitted: (str) => switchScreen(str, context),
              ),
              FlatButton(
                child: Text("Take me to the upload screen"),
                onPressed: () => switchScreen(controller.text, context),
              )
            ],
          ),
        ));
  }
}

class UploadPage extends StatefulWidget {
  UploadPage({Key key, this.url}) : super(key: key);
  final String url;

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String state = "";
  File _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter File Upload Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null ? Text('No image selected.') : Image.file(_image),
            if (_image != null) ...[
              RaisedButton(
                  child: Text('Upload Via Http'),
                  onPressed: () async {
                    var res = await uploadImageHTTP(_image, widget.url);
                    setState(() {
                      state = res;
                      print(res);
                    });
                  }),
              RaisedButton(
                  child: Text('Upload Via Dio'),
                  onPressed: () async {
                    var res = await uploadImageDio(_image, widget.url);
                    setState(() {
                      state = res;
                      print(res);
                    });
                  }),
              RaisedButton(
                  child: Text('Upload Via Chopper'),
                  onPressed: () async {
                    var res = await uploadImageChopper(_image, widget.url);
                    setState(() {
                      state = res;
                      print(res);
                    });
                  })
            ],
            Text(state)
          ],
        ),
      ),
      floatingActionButton: FloatingActionRow(
        color: Colors.blueAccent,
        children: <Widget>[
          FloatingActionRowButton(
              icon: Icon(Icons.image),
              onTap: () async {
                var file =
                    await ImagePicker.pickImage(source: ImageSource.gallery);
                var comperssedFile = await compressAndGetFile(file);
                setState(() {
                  if (comperssedFile != null) _image = comperssedFile;
                  state = '';
                });
              }),
          FloatingActionRowDivider(),
          FloatingActionRowButton(
              icon: Icon(Icons.camera),
              onTap: () async {
                var file =
                    await ImagePicker.pickImage(source: ImageSource.camera);
                var comperssedFile = await compressAndGetFile(file);
                setState(() {
                  if (comperssedFile != null) _image = comperssedFile;
                  state = '';
                });
              }),
        ],
      ),
    );
  }
}

Future<File> compressAndGetFile(File file) async {
  var value = Random.secure().nextInt(1000);
  final dir = await path_provider.getTemporaryDirectory();
  print('dir = $dir');
  final targetPath = dir.absolute.path + "/temp$value.jpg";
  var result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: 25,
  );

  print('File size before compress' + file.lengthSync().toString());
  print('File size after compress' + result.lengthSync().toString());

  return result;
}

Future<String> uploadImageDio(file, url) async {
  DioLib.Dio dio = new DioLib.Dio();
  DioLib.Response response;

  dio.interceptors.add(DioLib.LogInterceptor(responseBody: false));
  DioLib.FormData formData = DioLib.FormData.fromMap(
      {"picture": await DioLib.MultipartFile.fromFile(file.path)});
  response = await dio.post(url, data: formData);
  return response.data.toString();
}

Future<String> uploadImageHTTP(file, url) async {
  var request = http.MultipartRequest('POST', Uri.parse(url));
  request.files.add(await http.MultipartFile.fromPath('picture', file.path));
  var res = await request.send();
  return res.reasonPhrase;
}

Future<String> uploadImageChopper(file, url) async {
  http.MultipartFile multipartFile =
      await http.MultipartFile.fromPath('picture', file.path);
  final response =
      await FileUploadService.create(url).fileUpload(multipartFile);
  return response.body.toString();
}
