import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photoapp/providers.dart';
import 'package:photoapp/view/photo_list_screen.dart';
import 'package:photoapp/view/sign_in_screen.dart';

Future<void> main() async {
  //flutterの初期化処理
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  if (Firebase.apps.isEmpty) {
    //firebase初期化
    await Firebase.initializeApp(
        options: FirebaseOptions(
      apiKey: dotenv.env['API_KEY']!,
      appId: dotenv.env['APP_ID']!,
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['PROJECT_ID']!,
      storageBucket: dotenv.env['STORAGE_BUCKET']!,
    ));
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Photo App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Consumer(
          builder: (context, ref, _) {
            //ユーザー情報の取得
            final asyncUser = ref.watch(userProvider);
            return asyncUser.when(data: (User? data) {
              return data == null ? const SignInScreen() : const PhotoListScreen();
            }, loading: () {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }, error: (error, stackTrace) {
              return const Scaffold(
                body: Center(
                  child: Text("エラーが発生しました"),
                ),
              );
            });
          },
        ));
  }
}
