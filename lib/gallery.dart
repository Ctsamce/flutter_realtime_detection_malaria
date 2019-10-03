import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
import 'package:path/path.dart' as path;

import 'models.dart';

typedef void Callback(List<dynamic> list, int h, int w);

class Gallery extends StatefulWidget {
  final Callback setRecognitions;
  final String model;
  final File imageUploaded;

  Gallery(this.model, this.setRecognitions, this.imageUploaded);

  @override
  _GalleryState createState() => new _GalleryState();
}

class _GalleryState extends State<Gallery> {
  CameraController controller;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();

    if (!isDetecting) {
      isDetecting = true;
      print("Reached here");

      int startTime = new DateTime.now().millisecondsSinceEpoch;
      File img = widget.imageUploaded;
      if (widget.model == mobilenet) {
        Tflite.runModelOnImage(
          path: path.extension(img.path),
          numResults: 2,
        ).then((recognitions) {
          int endTime = new DateTime.now().millisecondsSinceEpoch;
          print("Detection took ${endTime - startTime}");

          widget.setRecognitions(recognitions, 900, 500);

          isDetecting = false;
        });
      } else if (widget.model == posenet) {
        Tflite.runPoseNetOnImage(
          path: path.extension(img.path),
          numResults: 2,
        ).then((recognitions) {
          int endTime = new DateTime.now().millisecondsSinceEpoch;
          print("Detection took ${endTime - startTime}");

          widget.setRecognitions(recognitions, 900, 500);

          isDetecting = false;
        });
      } else {
        Tflite.detectObjectOnImage(
          path: img.uri.path,
          model: "SSDMobileNet",
          imageMean: widget.model == yolo ? 0 : 127.5,
          imageStd: widget.model == yolo ? 255.0 : 127.5,
          numResultsPerClass: 1,
          threshold: widget.model == yolo ? 0.2 : 0.4,
        ).then((recognitions) {
          int endTime = new DateTime.now().millisecondsSinceEpoch;
          print("Detection took ${endTime - startTime}");

          widget.setRecognitions(recognitions, 900, 500);
          isDetecting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(controller),
    );
  }
}
