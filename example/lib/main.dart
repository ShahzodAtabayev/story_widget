import 'package:flutter/material.dart';
import 'package:story_widget/models/story_item.dart';
import 'package:story_widget/models/user_info.dart';
import 'package:story_widget/story_widget.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Story View',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return const WhatsAppStoryViewExample();
                }),
              );
            },
            child: Text('Open'),
          ),
        ],
      ),
    );
  }
}

class WhatsAppStoryViewExample extends StatefulWidget {
  const WhatsAppStoryViewExample({super.key});

  @override
  State<WhatsAppStoryViewExample> createState() => _WhatsAppStoryViewExampleState();
}

class _WhatsAppStoryViewExampleState extends State<WhatsAppStoryViewExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StoryWidget(
        storyItems: const [
          StoryItem(
            url:
                "https://plus.unsplash.com/premium_photo-1669741908308-5ca216f3fcd1?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1469&q=80",
            type: StoryItemType.image,
            viewers: [],
            duration: 3,
          ),
          StoryItem(
            url:
                "https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=687&q=80",
            type: StoryItemType.image,
            viewers: [],
            duration: 5,
          ),
          StoryItem(
            viewers: [],
            duration: 27,
            type: StoryItemType.video,
            url: "https://minio.salomtv.uz/stories/99d2b367-948f-4cde-aef8-bba8f1fee650/master.m3u8",
          ),
          StoryItem(
            viewers: [],
            duration: 27,
            type: StoryItemType.video,
            url: "https://minio.salomtv.uz/stories/99d2b367-948f-4cde-aef8-bba8f1fee650/master.m3u8",
          ),
        ],
        onComplete: () {
          print("Completed");
        },
        // called when stories completed
        onPageChanged: (index) {
          print("currentPageIndex = $index");
        },
        // returns current page index
        caption: "This is very beautiful STORY",
        // optional caption will be show up on first story item.
        createdAt: DateTime.now(),
        // if not specified current date would be taken
        enableOnHoldHide: false,
        indicatorPadding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16),
        // By default true
        indicatorColor: Colors.grey[500],
        // You can modify it whichever you like :)
        indicatorHeight: 2,
        // You can modify it whichever you like :)
        indicatorValueColor: Colors.white,
        storyGroup: StoryGroup(
          title: 'Премьеры от SalomTV ✨',
          subtitle: 'Serjan Bratan',
        ),
        muteIcon: const Icon(
          Icons.volume_mute,
          color: Colors.white,
        ),
        unmuteIcon: const Icon(
          Icons.volume_down_sharp,
          color: Colors.white,
        ),
        bottomButton: SafeArea(
          bottom: true,
          minimum: const EdgeInsets.only(bottom: 20, right: 16, left: 16),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Смотреть',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
