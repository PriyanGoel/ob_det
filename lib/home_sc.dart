import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:ob_det/main.dart';
// import 'package:tflite/tflite.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    // imgCamera = ;
    super.initState();
    initcamera();
    loadmodel();
    ini();
  }

  @override
  void dispose() async {
    super.dispose();
    await Tflite.close();
    camcont.dispose();
  }

  objectdetector(CameraImage img) async {
    var detector = await Tflite.runModelOnFrame(
      bytesList: img.planes.map((e) {
        return e.bytes;
      }).toList(),
      // asynch: true,
      imageHeight: img.height,
      imageWidth: img.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 3,
      threshold: 0.1,
      asynch: true,
    );

    if (detector != null) {
      log("res is $detector" as num);
    }
  }

  void ini() async {
    await Future.delayed(
      const Duration(seconds: 12),
    );
  }

  bool isworking = false;
  String res = "";
  late CameraImage imgCamera;
  late CameraController camcont;

  loadmodel() async {
    final interpreter =
        await tfl.Interpreter.fromAsset("assests/mobilenet_v1_1.0_224.tflite");

    await Tflite.loadModel(
      model: "assests/mobilenet_v1_1.0_224.tflite",
      labels: "assests/mobilenet_v1_1.0_224.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  initcamera() {
    camcont = CameraController(cameras[0], ResolutionPreset.low);
    camcont.initialize().then((value) {
      if (!mounted) {
        print("fuck");
        return;
      }
      setState(() {
        camcont.startImageStream((image) => {
              if (!isworking)
                {
                  isworking = true,
                  imgCamera = image,
                }
            });
      });
    });
  }

  runmodel() async {
    if (imgCamera != null) {
      var recog = await Tflite.runModelOnFrame(
        bytesList: imgCamera.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: imgCamera.height,
        imageWidth: imgCamera.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 3,
        threshold: 0.1,
        asynch: true,
      );

      res = "";

      recog?.forEach((response) {
        res = response["label"] +
            "   " +
            (response["confidence"] as double).toStringAsFixed(2) +
            "\n\n";
      });
      setState(() {
        res;
      });
      isworking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              initcamera();
            },
            child: Center(
              child: Container(
                height: 270,
                width: 360,
                child: imgCamera == null
                    ? Container()
                    : AspectRatio(
                        aspectRatio: camcont.value.aspectRatio,
                        child: CameraPreview(camcont),
                      ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Text(res),
            ),
          )
        ],
      ),
    );
  }
}
