import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photoapp/view/photo_list_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); //CHECK: どういう意味
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Photo App",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "メールアドレス"),
                  keyboardType: TextInputType
                      .emailAddress, //どんなデータを入力させるかによって表示させるキーボードの種類を変える
                  validator: (String? value) {
                    //入力されていない場合
                    if (value?.isEmpty == true) {
                      return "メールアドレスを入力してください";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "パスワード"),
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true, //入力された文字を隠す
                  validator: (String? value) {
                    //入力されていない場合
                    if (value?.isEmpty == true) {
                      return "パスワードを入力してください";
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                SizedBox(
                  width: double.infinity,
                  //ボタン
                  child: ElevatedButton(
                    onPressed: () => _onSignIn(),
                    child: const Text("ログイン"),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _onSignUp(),
                      child: const Text("新規登録"),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSignIn() async {
    try {
      //入力内容の確認
      if (_formKey.currentState?.validate() != true) {
        //エラーメッセージがあるため処理を中断する = 押しても意味がない
        return;
      }
      final String email = _emailController.text;
      final String password = _passwordController.text;
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      //画像一覧画面に切り替え
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PhotoListScreen(),
        ),
      );
    } catch (e) {
      //失敗したらエラーメッセージを表示
      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("エラー"),
              content: Text(e.toString()),
            );
          });
    }
  }

  Future<void> _onSignUp() async {
    try {
      if (_formKey.currentState?.validate() != true) {
        return;
      }

      final String email = _emailController.text;
      final String password = _passwordController.text;
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;
      //画像一覧表示に切り替え
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PhotoListScreen(),
        ),
      );
    } catch (e) {
      //失敗したらエラーメッセージを表示
      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("エラー"),
              content: Text(e.toString()),
            );
          });
    }
  }
}
