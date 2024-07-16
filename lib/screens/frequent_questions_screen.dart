import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FrequentQuestionsScreen extends StatefulWidget {
  @override
  FrequentQuestionsScreenState createState() => FrequentQuestionsScreenState();
}

class FrequentQuestionsScreenState extends State<FrequentQuestionsScreen> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _controller.loadRequest(Uri.parse('https://www.flutter.dev'));
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: darkTheme? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: darkTheme? Colors.black: Colors.white,
        title: Text("Preguntas frecuentes",
          style: TextStyle(
              color: darkTheme ? Colors.amber.shade400 : Colors.black
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: darkTheme ? Colors.amber.shade400 : Colors.black),
          onPressed: (){
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
