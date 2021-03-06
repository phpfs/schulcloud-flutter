import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached/flutter_cached.dart';
import 'package:schulcloud/app/app.dart';

import '../data.dart';
import '../service.dart';

class UploadFab extends StatefulWidget {
  const UploadFab({@required this.path}) : assert(path != null);

  final FilePath path;

  @override
  _UploadFabState createState() => _UploadFabState();
}

class _UploadFabState extends State<UploadFab> {
  /// Controller for the [SnackBar].
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackBar;

  void _startUpload(BuildContext context) async {
    final updates = services.files.uploadFiles(
      files: await FilePicker.getMultiFile(),
      path: widget.path,
    );

    snackBar = context.scaffold.showSnackBar(SnackBar(
      duration: Duration(days: 1),
      content: Row(
        children: <Widget>[
          Transform.scale(
            scale: 0.5,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<UploadProgressUpdate>(
              stream: updates,
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  scheduleMicrotask(_onUpdateComplete);
                }
                if (!snapshot.hasData) {
                  return Container();
                }
                final info = snapshot.data;
                return Text(
                  context.s.file_uploadProgressSnackBarContent(
                    info.totalNumberOfFiles,
                    info.currentFileName,
                    info.index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ));
  }

  void _onUpdateComplete() {
    snackBar.close();
    context.scaffold.showSnackBar(SnackBar(
      duration: Duration(seconds: 2),
      content: Text(context.s.file_uploadCompletedSnackBar),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return CachedRawBuilder<User>(
      controller: services.storage.userId.controller,
      builder: (context, update) {
        if (update.hasNoData ||
            !update.data.hasPermission(Permission.fileStorageCreate)) {
          return SizedBox();
        }

        return FloatingActionButton(
          onPressed: () => _startUpload(context),
          child: Icon(Icons.file_upload),
        );
      },
    );
  }
}
