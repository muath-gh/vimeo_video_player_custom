import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flick_video_player_custom/flick_video_player_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:collection/collection.dart';
import 'package:vimeo_video_player_custom/vimeo_video_player_custom.dart';

class VimeoVideoPlayer extends StatefulWidget {
  /// vimeo video url
  final String url;

  final String vimeoId;

  /// access token
  final String accessToken;

  /// hide/show device status-bar
  final List<SystemUiOverlay> systemUiOverlay;

  /// deviceOrientation of video view
  final List<DeviceOrientation> deviceOrientation;

  /// If this value is set, video will have initial position
  /// set to given minute/second.
  ///
  /// Incorrect values (exceeding the video duration) will be ignored.
  final Duration? startAt;

  /// If this function is provided, it will be called periodically with
  /// current video position (approximately every 500 ms).
  final void Function(Duration timePoint)? onProgress;

  /// If this function is provided, it will be called when video
  /// finishes playback.
  final VoidCallback? onFinished;

  /// to auto-play the video once initialized
  final bool autoPlay;
  final bool looping;

  const VimeoVideoPlayer({
    required this.url,
    required this.vimeoId,
    required this.accessToken,
    this.systemUiOverlay = const [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ],
    this.deviceOrientation = const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    this.startAt,
    this.onProgress,
    this.onFinished,
    this.autoPlay = false,
    this.looping = false,
    Key? key,
  }) : super(key: key);

  @override
  State<VimeoVideoPlayer> createState() => VimeoVideoPlayerState();
}

class VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  /// video player controller
  VideoPlayerController? _videoPlayerController;

  final VideoPlayerController _emptyVideoPlayerController =
      VideoPlayerController.network('');

  /// flick manager to manage the flick player
  FlickManager? _flickManager;

  /// used to notify that video is loaded or not
  ValueNotifier<bool> isVimeoVideoLoaded = ValueNotifier(false);

  /// used to check that the url format is valid vimeo video format
  bool get _isVimeoVideo {
    var regExp = RegExp(
      r"^((https?)://)?(www.)?vimeo\.com/(\d+).*$",
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(widget.url);
    if (match != null && match.groupCount >= 1) return true;
    return false;
  }

  /// used to check that the video is already seeked or not
  bool _isSeekedVideo = false;

  List<ProgressiveModel?> vimeoProgressiveList = [];

  ProgressiveModel? vimeoProgressiveSelected;

  @override
  void initState() {
    super.initState();

    /// checking that vimeo url is valid or not
    // if (_isVimeoVideo) {

    // }
    videoPlayer(widget.vimeoId, false);
  }

  @override
  void deactivate() {
    _flickManager?.flickControlManager?.pause();
    _videoPlayerController?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    /// disposing the controllers
    _flickManager?.dispose();
    if (_videoPlayerController?.value.isPlaying ?? false)
      _videoPlayerController?.pause();
    _videoPlayerController?.removeListener(() {});
    _videoPlayerController = null;
    _videoPlayerController?.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    ); // to re-show bars
    super.dispose();
  }

  void _setVideoInitialPosition() {
    final Duration? startAt = widget.startAt;

    if (startAt != null && _videoPlayerController != null) {
      _videoPlayerController!.addListener(() {
        final VideoPlayerValue videoData = _videoPlayerController!.value;
        if (videoData.isInitialized &&
            videoData.duration > startAt &&
            !_isSeekedVideo) {
          _videoPlayerController!.seekTo(startAt);
          _isSeekedVideo = true;
        } // else ignore, incorrect value
      });
    }
  }

  void _setVideoListeners() {
    final onProgressCallback = widget.onProgress;
    final onFinishCallback = widget.onFinished;

    if (_videoPlayerController != null &&
        (onProgressCallback != null || onFinishCallback != null)) {
      _videoPlayerController!.addListener(() {
        final VideoPlayerValue videoData = _videoPlayerController!.value;
        if (videoData.isInitialized) {
          // if (!isLooping) {
          if (videoData.isPlaying) {
            if (onProgressCallback != null) {
              onProgressCallback.call(videoData.position);
            }
          } else if (videoData.duration == videoData.position) {
            if (onFinishCallback != null) {
              onFinishCallback.call();
            }
          }
          // } else {
          //   if (onProgressCallback != null) {
          //     onProgressCallback.call(videoData.position);
          //   }
          //   if (videoData.duration.inSeconds <= videoData.position.inSeconds) {
          //     if (onFinishCallback != null) {
          //       onFinishCallback.call();
          //     }
          //   }
          // }
        }
      });
    }
  }

  void videoPlayer(String vimeoVideoId, bool firstVideo) {
    if (vimeoVideoId.isNotEmpty) {
      /// getting the vimeo video configuration from api and setting managers
      _getVimeoVideoConfigFromVimeoId(vimeoVideoId).then((value) async {
        vimeoProgressiveList = value?.play?.progressive ?? [];

        vimeoProgressiveList.sort(
            (a, b) => (a?.qualityInt ?? 0).compareTo((b?.qualityInt ?? 0)));
        String vimeoMp4Video = '';

        if (vimeoProgressiveList.isNotEmpty) {
          String? video720 = vimeoProgressiveList
              .singleWhereOrNull((element) => element?.qualityInt == 720)
              ?.link;
          vimeoProgressiveSelected = video720 != null
              ? vimeoProgressiveList
                  .singleWhereOrNull((element) => element?.qualityInt == 720)
              : vimeoProgressiveList.last;

          vimeoMp4Video = video720 ?? (vimeoProgressiveList.last?.link ?? '');
          if (vimeoMp4Video.isEmpty || vimeoMp4Video == '') {
            showAlertDialog(context);
          }
        }

        if (!firstVideo) {
          isVimeoVideoLoaded.value = false;
          VideoPlayerController? _old = _videoPlayerController;
          if (mounted) {
            setState(() {
            if(_videoPlayerController != null){
              _videoPlayerController!.pause();
              _videoPlayerController = null;
            }
            });
          }
          Future.delayed(const Duration(seconds: 1), () {
            if (_old != null) _old.dispose();
          });
        }
        _videoPlayerController = VideoPlayerController.network(vimeoMp4Video);

        _setVideoInitialPosition();
        _setVideoListeners();

        _flickManager = FlickManager(
            videoPlayerController: _videoPlayerController!,
            autoPlay: widget.autoPlay,
            additionalOptions: [
              OptionModel(
                  name: 'Quality',
                  icon: Icons.hd_outlined,
                  onPressFeature: () => _onPressQualityOption())
            ])
          ..registerContext(context);

        isVimeoVideoLoaded.value = !isVimeoVideoLoaded.value;
        print('isVimeoVideoLoaded');
        print(isVimeoVideoLoaded.value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double? videoHeight = _videoPlayerController?.value.size.height;
    double? videoWidth = _videoPlayerController?.value.size.width;

    return ValueListenableBuilder(
      valueListenable: isVimeoVideoLoaded,
      builder: (context, bool isVideo, child) => Container(
        child: isVideo
            ? FlickVideoPlayer(
                key: ObjectKey(_flickManager),
                flickManager: _flickManager ??
                    FlickManager(
                        videoPlayerController: _emptyVideoPlayerController,
                        autoPlay: widget.autoPlay),
              )
            : LayoutBuilder(builder: (ctx, size) {
                double aspectRatio = (size.maxHeight == double.infinity ||
                        size.maxWidth == double.infinity)
                    ? (_videoPlayerController?.value.isInitialized == true
                        ? _videoPlayerController?.value.aspectRatio
                        : (16 / 9))!
                    : size.maxWidth / size.maxHeight;
                return AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Container(
                    height: videoHeight,
                    width: videoWidth,
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Center(
                      child: Transform.scale(
                        scale: 0.8,
                        child: const CircularProgressIndicator(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                );
              }),
      ),
    );
  }

  /// used to get valid vimeo video configuration
  Future<VimeoModel?> _getVimeoVideoConfigFromVimeoId(
    String vimeoId, {
    bool trimWhitespaces = true,
  }) async {
    /// here i'm converting the vimeo video id only and calling config api for vimeo video .mp4
    /// supports this types of urls
    /// https://vimeo.com/70591644 => 70591644
    /// www.vimeo.com/70591644 => 70591644
    /// vimeo.com/70591644 => 70591644

    final response = await _getVimeoVideoConfig(vimeoVideoId: vimeoId);
   
   
    return (response != null) ? response : null;
  }

  /// give vimeo video configuration from api
  Future<VimeoModel?> _getVimeoVideoConfig({
    required String vimeoVideoId,
  }) async {
    try {
      Response responseData =
          await Dio().get('https://api.vimeo.com/videos/$vimeoVideoId',
              options: Options(
                headers: {
                  'Authorization': 'bearer ${widget.accessToken}',
                },
                receiveTimeout: const Duration(milliseconds: 30000),
                sendTimeout: const Duration(milliseconds: 30000),
              ));
      var vimeoVideo = VimeoModel.fromJson(responseData.data);
      print('ssssssssssssssssssssssssssssssssssssssss');
      print(vimeoVideo.play!.progressive!.first.link);
  
      return vimeoVideo;
    } on DioException catch (e) {

      log('Dio Error : ', name: e.error.toString());
      return null;
    } on Exception catch (e) {
     
      log('Error : ', name: e.toString());
      return null;
    }
  }

  Future<void> _onPressQualityOption() async {
    Navigator.pop(context);
    dynamic response = await showModalBottomSheet(
        context: context,
        builder: (context) => SheetQualityComp(
            vimeoProgressiveList: vimeoProgressiveList,
            vimeoProgressiveSelected: vimeoProgressiveSelected));
    if (response == null) return;
    if (response == vimeoProgressiveSelected) return;
    vimeoProgressiveSelected = response;
    Duration? duration =
        await _flickManager?.flickVideoManager?.videoPlayerController?.position;
    _videoPlayerController =
        VideoPlayerController.network(vimeoProgressiveSelected?.link ?? '');
    _flickManager?.handleChangeVideo(
        _videoPlayerController ?? _emptyVideoPlayerController,
        videoChangeDuration: duration,
        isKeepValueVideo: true);
    _flickManager?.flickControlManager?.togglePlay();
    setState(() {});
  }
}

// ignore: library_private_types_in_public_api
extension ShowAlertDialog on VimeoVideoPlayerState {
  showAlertDialog(BuildContext context) {
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Alert"),
      content: const Text("Some thing wrong with this url"),
      actions: [
        TextButton(
          child: const Text("OK"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
