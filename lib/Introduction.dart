import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:thesis/main.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({Key? key}) : super(key: key);

  @override
  OnBoardingPageState createState() => OnBoardingPageState();
}

class OnBoardingPageState extends State<OnBoardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MyHomePage()), //Goes to main screen
    );
  }

  Widget _buildImage(String assetName, [double width = 250]) {
    return Image.asset('assets/$assetName', width: width);
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    box.put('passed', 1);

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      autoScrollDuration: 3000,
      //infiniteAutoScroll: true,

      pages: [
        PageViewModel(
          title: "Main Screen",
          bodyWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImage('main_screen.png'),
              const SizedBox(height: 12),
              const Text(
                "This is the main screen which contains the step counter and the buttons to the rest of the screens.",
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Route",
          bodyWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImage('route_screen.png'),
              const SizedBox(height: 20),
              const Text(
                "This screen shows the map and the position of the user.",
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Compass",
          bodyWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImage('compass_screen.png'),
              const SizedBox(height: 12),
              const Text(
                "This screen shows your current degree, the coordinates and the altitude of the user.",
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Sensors",
          bodyWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImage('sensors_screen.jpg'),
              const SizedBox(height: 20),
              const Text(
                "This scren shows the total steps and readings of each available sensor.",
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Settings",
          bodyWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImage('settings_screen.jpg'),
              const SizedBox(height: 20),
              const Text(
                "This is the settings screen on which the user can change various settings such as the sampling rate of the sensors or save the .db file to the device.",
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          decoration: pageDecoration,
        ),
      ],

      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      //rtl: true, // Display as right-to-left
      back: const Icon(Icons.arrow_back),
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: kIsWeb
          ? const EdgeInsets.all(12.0)
          : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        color: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}
