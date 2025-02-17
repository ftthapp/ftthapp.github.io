import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ftthapp/auth/authpage.dart';
import 'package:ftthapp/auth/main.dart';
Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await Firebase.initializeApp(
      options: const FirebaseOptions(apiKey: "AIzaSyBaZ2kbjIVmEHwe-2PlsU1RtXEQv-I_CQE",
        appId: "1:921875173287:android:9e71660784a800e0413082",
        messagingSenderId: "921875173287",
        projectId: "ftthapp-136f5",
        //   storageBucket: "gs://schoolportal-88528.appspot.com",

      )
  );

  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,

      ),
      home: MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

