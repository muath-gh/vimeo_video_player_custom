import 'package:flutter/material.dart';
import 'package:vimeo_video_player_custom/vimeo_video_player_custom.dart';
import 'package:vimeo_player_flutter/vimeo_player_flutter.dart';
import 'package:video_player/video_player.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vimeo Video Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Vimeo video player demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController vimeoVideoPlayerController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    vimeoVideoPlayerController = VideoPlayerController.network('');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
           
          
            
          ],
        ),
      ),
    );
  }

  void onFinishedVimeo() {
    debugPrint('onFinishedVimeo');
  }
}
