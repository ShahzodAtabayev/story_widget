import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:story_widget/models/story_item.dart';
import 'package:story_widget/models/user_info.dart';
import 'package:story_widget/widgets/story_image.dart';
import 'package:story_widget/widgets/story_video.dart';
import 'package:story_widget/widgets/story_indicator.dart';

/// A StatefulWidget that displays a series of story items with a customizable
/// progress indicator and user-defined callback functions for navigation and
/// completion events.
///
/// The `FlutterStoryView` takes a list of `StoryItem` objects, and displays them
/// one at a time, advancing to the next item after a specified duration.
///
/// The widget also provides a set of callback functions that can be used to
/// handle user interactions, such as tapping on the screen to pause, resume,
/// or navigate between story items.
///
/// The `onComplete` callback is triggered when all items have been displayed,
/// while the `onPageChanged` callback is triggered every time the currently
/// displayed item changes.

/// [OnPageChanged] is called when a story item changes
typedef OnPageChanged = Function(int value);
typedef ButtonBuilder = Widget Function(int value);

class StoryWidget extends StatefulWidget {
  /// This Calls when story is completed
  final VoidCallback onComplete;

  /// [OnPageChanged] is called when a story item changes
  final OnPageChanged onPageChanged;

  final VoidCallback? onMenuTapListener;

  final List<StoryItem> storyItems;

  final Widget muteIcon;

  final Widget unmuteIcon;

  final ButtonBuilder? bottomButton;

  // Optional caption for the story
  final String? caption;

  /// User Info e.g username and profile image
  final StoryGroup storyGroup;

  /// Time when the story has been created
  final DateTime? createdAt;

  /// Height of the indicator
  final double? indicatorHeight;

  // Background color of indicator
  final Color? indicatorColor;

  // Background color of indicator
  final Color? indicatorValueColor;

  final bool? enableOnHoldHide;

  // Back button on the top left
  final bool? showBackIcon;

  // Menu button on the top right
  final bool? showMenuIcon;

  // Show reply button
  final bool? showReplyButton;

  // Reply button text
  final String? replyButtonText;

  // Reply button functionality
  final VoidCallback? onReplyTap;

  // Padding of indicator
  final EdgeInsets? indicatorPadding;

  const StoryWidget({
    super.key,
    required this.onComplete,
    required this.onPageChanged,
    this.caption,
    this.onMenuTapListener,
    required this.storyGroup,
    this.createdAt,
    required this.storyItems,
    this.indicatorHeight,
    this.indicatorColor,
    this.indicatorValueColor,
    this.enableOnHoldHide = true,
    this.showBackIcon = true,
    this.showMenuIcon = true,
    this.showReplyButton = true,
    this.replyButtonText = "Reply",
    this.onReplyTap,
    this.indicatorPadding = const EdgeInsets.only(top: 40.0),
    required this.muteIcon,
    required this.unmuteIcon,
    this.bottomButton,
  });

  @override
  _StoryWidgetState createState() => _StoryWidgetState();
}

class _StoryWidgetState extends State<StoryWidget> with TickerProviderStateMixin {
  /// Main Controller
  AnimationController? _animationController;
  VideoPlayerController? _videoController;
  Animation<double>? _animation;

  /// current story item index
  int currentItemIndex = 0;

  bool _isMute = false;

  /// current progress
  double _progress = 0;

  /// This [_tapDownTime] to indicate how long the story is being hold on finger
  /// so that we can easily find out to resume timer or switch to the next page.
  DateTime? _tapDownTime;

  /// This [_timer] is used to determine if the onTapDown is holded for 200 milliseconds
  /// long or less than this. So that we can find out to go to Next story or
  /// just hide the top and bottom menu on hold.
  Timer? _timer;

  bool _isVideoLoading = false;

  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    /// Start playing the story by calling _playStory method
    _playStory(currentItemIndex);
    // Notify the onPageChanged callback about the current item index
    widget.onPageChanged(currentItemIndex);
  }

  // Start playing the story at the given index
  void _playStory(int index) {
    /// If story is video
    var story = widget.storyItems[index];

    if (story.type == StoryItemType.video) {
      /// Dispose the previous _videoController (if any) before initializing new one.
      _videoController?.dispose();

      setState(() {
        _isVideoLoading = true; // Set loading to true when video starts loading
      });
      // Check if the URL is an asset or a network URL
      bool isAsset = story.url.startsWith('assets/');

      _videoController =
          isAsset ? VideoPlayerController.asset(story.url) : VideoPlayerController.networkUrl(Uri.parse(story.url));

      _videoController!.initialize().then((_) {
        setState(() {
          _isVideoLoading = false;
          _isPaused = false;
        });
        _videoController!.play();

        // Limit video duration to 30 seconds
        if (_videoController!.value.duration.inSeconds > 30) {
          _videoController!.setLooping(false); // Disable looping
          Timer(const Duration(seconds: 30), () {
            _onAnimationCompleted();
            _videoController!.pause();
          });
        } else {
          _videoController!.setLooping(true); // Enable looping
        }

        Duration clampedDuration = _videoController!.value.duration.inSeconds > 30
            ? const Duration(seconds: 30)
            : _videoController!.value.duration;
        _startAnimation(index, duration: clampedDuration);
      });
    } else {
      _startAnimation(index); // Pass index without video duration
    }
  }

  void _startAnimation(int index, {Duration? duration}) {
    Duration storyDuration = duration ?? Duration(seconds: widget.storyItems[index].duration!);

    _animationController = AnimationController(
      vsync: this,
      duration: storyDuration,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController!)
      ..addListener(() {
        setState(() {
          _progress = _animation!.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onAnimationCompleted();
        }
      });

    setState(() {
      _progress = 0.0; // Set progress to 0 before starting the animation
    });

    _animationController!.forward();
  }

  // Handles the completion of the story animation
  void _onAnimationCompleted() {
    if (currentItemIndex == widget.storyItems.length - 1) {
      widget.onComplete();
    } else {
      currentItemIndex++;
      widget.onPageChanged(currentItemIndex);
      setState(() {
        _progress = 0.0; // Reset progress value to 0 when the story automatically advances
      });
      _playStory(currentItemIndex);
    }
  }

  // Handles tap action to go to the next story item
  void _onTapNext() {
    // To prevent moving to the next story if the video is still loading
    if (_isVideoLoading) return;

    if (currentItemIndex == widget.storyItems.length - 1) {
      widget.onComplete();
    } else {
      currentItemIndex++;
      widget.onPageChanged(currentItemIndex);
      _animationController!.dispose();
      setState(() {
        _progress = 0.0; // Reset progress value to 0 when tapping next
      });
      _playStory(currentItemIndex);
    }
  }

  // Handles tap action to go to the previous story item
  void _onTapPrevious() {
    if (currentItemIndex == 0) {
      // You can perform something here :)
    } else {
      currentItemIndex--;
      widget.onPageChanged(currentItemIndex);
      _animationController!.dispose();
      setState(() {
        _progress = 0.0; // Reset progress value to 0 when tapping next
      });
      _playStory(currentItemIndex);
    }
  }

  // Pause the story timer
  void _pauseTimer() {
    _animationController!.stop();
    _videoController?.pause();
    setState(() {});
  }

  // Resume the story timer
  void _resumeTimer() {
    _animationController!.forward();
    _videoController?.play();
    setState(() {});
  }

  // Dispose of the animation controller when the widget is disposed
  @override
  void dispose() {
    _animationController?.dispose();
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: GestureDetector(
        child: Stack(
          children: [
            /// All story items mapped in the Stack widget
            Stack(
              children: List.generate(
                widget.storyItems.length,
                (index) {
                  var story = widget.storyItems[index];
                  return Visibility(
                    visible: currentItemIndex == index,
                    maintainState: true,
                    child: _storyItem(story),
                  );
                },
              ),
            ),

            /// Story indicator which plays with timer, progress and total story Items
            /// check out widget in widgets dir.
            Align(
              alignment: Alignment.topCenter,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.enableOnHoldHide == false
                    ? 1
                    : !_isPaused
                        ? 1
                        : 0,
                child: StoryIndicator(
                  progress: _progress,
                  currentItemIndex: currentItemIndex,
                  indicatorColor: widget.indicatorColor,
                  storyItemsLen: widget.storyItems.length,
                  indicatorHeight: widget.indicatorHeight,
                  indicatorPadding: widget.indicatorPadding,
                  indicatorValueColor: widget.indicatorValueColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Creates a single story item widget
  _storyItem(StoryItem story) {
    return Stack(
      children: [
        Visibility(
          visible: currentItemIndex == widget.storyItems.indexOf(story) &&
              story.type == StoryItemType.video &&
              (_videoController == null || !_videoController!.value.isInitialized) &&
              _isVideoLoading,
          child: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),
        ),

        _switchStoryItemIsVideoOrImage(
          story.url,
          type: story.type,
          controller: _videoController, // Pass the controller
        ),

        // Next story area
        Align(
          alignment: Alignment.centerRight,
          heightFactor: 1,
          child: GestureDetector(
            onTapDown: (details) {
              _tapDownTime = DateTime.now();
              _timer = Timer(const Duration(milliseconds: 200), () {
                _timer = null;
                if (_tapDownTime != null && _isVideoLoading == false) {
                  final elapsedTime = DateTime.now().difference(_tapDownTime!).inMilliseconds;
                  if (elapsedTime >= 200) {
                    setState(() => _isPaused = true);
                    _pauseTimer();
                  } else {
                    /// Do nothing if the onTapDown is tapped less than 200 milliseconds
                  }
                }
              });
            },
            onTapCancel: () {
              _resumeTimer();
              setState(() => _isPaused = false);
            },
            onTapUp: (details) {
              if (_tapDownTime != null) {
                final elapsedTime = DateTime.now().difference(_tapDownTime!).inMilliseconds;
                if (elapsedTime > 200) {
                  _resumeTimer();
                  setState(() => _isPaused = false);
                } else {
                  _onTapNext();
                }
                _tapDownTime = null;
              }
            },
          ),
        ),

        // Previous story area
        Align(
          alignment: Alignment.centerLeft,
          heightFactor: 1,
          child: SizedBox(
            width: 70,
            child: GestureDetector(
              onTapDown: (details) {
                _tapDownTime = DateTime.now();
                _timer = Timer(const Duration(milliseconds: 200), () {
                  _timer = null;
                  if (_tapDownTime != null && _isVideoLoading == false) {
                    final elapsedTime = DateTime.now().difference(_tapDownTime!).inMilliseconds;
                    if (elapsedTime >= 200) {
                      setState(() => _isPaused = true);
                      _pauseTimer();
                    } else {
                      /// Do nothing if the onTapDown is tapped less than 200 milliseconds
                    }
                  }
                });
              },
              onTapCancel: () {
                _resumeTimer();
                setState(() => _isPaused = false);
              },
              onTapUp: (details) {
                if (_tapDownTime != null) {
                  final elapsedTime = DateTime.now().difference(_tapDownTime!).inMilliseconds;
                  if (elapsedTime > 200) {
                    _resumeTimer();
                    setState(() => _isPaused = false);
                  } else {
                    _onTapPrevious(); // return to previous story
                  }
                  _tapDownTime = null;
                }
              },
            ),
          ),
        ),
        if (widget.bottomButton != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: widget.bottomButton!.call(currentItemIndex),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.enableOnHoldHide == false
                ? 1
                : !_isPaused
                    ? 1
                    : 0,
            child: Container(
              height: 36,
              margin: EdgeInsets.only(
                left: 16,
                right: 4,
                top: MediaQuery.of(context).padding.top + 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.storyItems[currentItemIndex].title ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              widget.storyItems[currentItemIndex].subtitle ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_isMute) {
                        _videoController?.setVolume(1);
                        setState(() => _isMute = false);
                      } else {
                        _videoController?.setVolume(0);
                        setState(() => _isMute = true);
                      }
                    },
                    icon: _isMute ? widget.muteIcon : widget.unmuteIcon,
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  _switchStoryItemIsVideoOrImage(
    String url, {
    required StoryItemType type,
    VideoPlayerController? controller,
  }) {
    bool isAsset = url.startsWith('assets/');
    switch (type) {
      case StoryItemType.image:
        return StoryImage.url(url, isAsset: isAsset);
      case StoryItemType.video:
        return StoryVideo.url(url, controller);
      // case StoryItemType.text:
      //   return StoryText.url(url, controller);
    }
  }
}
