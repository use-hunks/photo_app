import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:photoapp/photo.dart';
import 'package:photoapp/photo_repository.dart';
import 'package:photoapp/providers.dart';
import 'package:photoapp/view/photo_view_screen.dart';
import 'package:photoapp/view/sign_in_screen.dart';

class PhotoListScreen extends ConsumerStatefulWidget {
  const PhotoListScreen({super.key});

  @override
  PhotoListScreenState createState() => PhotoListScreenState();
}

class PhotoListScreenState extends ConsumerState<PhotoListScreen> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: ref.read(photoListIndexProvider));
  }

  void _onPageChanged(int index) {
    //XXX: これどこの操作を表してる？？
    ref.read(photoListIndexProvider.notifier).state = index;
  }

  void _onTapBottomNavigatingItem(int index) {
    //PageViewで表示されているWidgetを切り替える
    _controller.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    ref.read(photoListIndexProvider.notifier).state = index;
  }

  void _onTapPhoto(Photo photo, List<Photo> photoList, bool isFavorite) {
    // 引数のphotoListをfavの場合, favoritePhotoListで受けとる
    final initialIndex = photoList.indexOf(photo);
    //最初に表示する画像のURLを指定して、画像詳細画面に切り替え
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProviderScope(overrides: [
              photoViewInitialIndexProvider.overrideWithValue(initialIndex)
            ], child:  PhotoViewScreen(isFavorite: isFavorite))));
  }

  Future<void> _onSignOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    //ログアウトに成功したらログイン画面に戻る
    if (context.mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const SignInScreen(),
      ));
    }
  }

  Future<void> _onAddPhoto() async {
    //画像ファイルを選択
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    //画像ファイルが選択された場合
    if (pickedFile != null) {
      //ログイン中のユーザー情報を取得
      final User user = FirebaseAuth.instance.currentUser!;
      final PhotoRepository repository = PhotoRepository(user);
      final File file = File(pickedFile.path); //CHECK: ほんとにあってる？
      await repository.addPhoto(file);
    }
  }

  Future<void> _onTapFav(Photo photo) async {
    final photoRepository = ref.read(photoRepositoryProvider);
    final toggledPhoto = photo.toggleIsFavorite();
    await photoRepository!.updatePhoto(toggledPhoto);
  }

  void _showSignOutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("サインアウト"),
        content: const Text("本当にサインアウトしますか？"),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("キャンセル")),
          ElevatedButton(
              onPressed: () {
                _onSignOut();
              },
              child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //ログインしているユーザーの情報を取得
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Photo App"),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(FirebaseAuth.instance.currentUser?.email ?? "ゲスト",
                    overflow: TextOverflow.ellipsis, //テキストが幅を超えるとき省略記号を示す
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
        actions: [
          //ログアウトのボタンを右上に配置
          IconButton(
            onPressed: () {
              _showSignOutConfirmationDialog(context);
            },
            icon: const Icon(Icons.exit_to_app),
          )
        ],
      ),
      body: PageView(
          controller: _controller,
          //表示が切り替わったとき
          onPageChanged: (int index) => _onPageChanged(index),
          children: [
            Consumer(
              builder: (context, ref, child) {
                final asyncPhotoList = ref.watch(photoListProvider);
                return asyncPhotoList.when(data: (List<Photo> photoList) {
                  return PhotoGridView(
                    photoList: photoList,
                    onTap: (photo) => _onTapPhoto(photo, photoList, false),
                    onTapFav: (photo) => _onTapFav(photo),
                  );
                }, loading: () {
                  return const Center(child: CircularProgressIndicator());
                }, error: (e, stackTrace) {
                  return Center(
                    child: Text(e.toString()),
                  );
                });
              },
            ),
            Consumer(builder: (context, ref, child) {
              final asyncFavoritePhotoList =
                  ref.watch(favoritePhotoListProvider);
              return asyncFavoritePhotoList.maybeWhen(
                  data: (List<Photo> photoList) {
                    return PhotoGridView(
                        photoList: photoList,
                        onTap: (photo) => _onTapPhoto(photo, photoList, true),
                        onTapFav: (photo) => _onTapFav(photo));
                  },
                  orElse: () =>
                      const Center(child: CircularProgressIndicator()));
            }),
          ]),
      //画像追加floatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddPhoto(),
        child: const Icon(Icons.add),
      ),
      //画面下部のボタン部分
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final photoIndex = ref.watch(photoListIndexProvider);
          return BottomNavigationBar(
            onTap: (int index) => _onTapBottomNavigatingItem(index),
            currentIndex: photoIndex,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.image), label: "フォト"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.favorite), label: "お気に入り"),
            ],
          );
        },
      ),
    );
  }
}

class PhotoGridView extends StatelessWidget {
  final List<Photo> photoList;
  final void Function(Photo photo) onTap; //コールバック関数の定義
  final void Function(Photo photo) onTapFav;

  PhotoGridView({
    super.key,
    required this.photoList,
    required this.onTap,
    required this.onTapFav,
  });

  final logger = Logger();
  @override
  Widget build(BuildContext context) {
    logger.i('PhotoList length: ${photoList.length}');
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(8),
      children: photoList.map((Photo photo) {
        //Stackを用いWidgetを前後に重ねる
        return Stack(
          children: [
            //画像一つ一つを表示
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: InkWell(
                //画像ひとつひとつが押されたら
                onTap: () => onTap(photo),
                child: Image.network(
                  photo.imageURL,
                  //画像の表示の仕方を調節
                  //比率は維持しつつ余白がでないようにするのでcoverを指定
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text('画像の読み込みに失敗しました: $error',
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ),
            //画像の上にお気に入りアイコンを重ねて表示
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => onTapFav(photo),
                color: photo.isFavorite ? Colors.pink : Colors.white,
                icon: photo.isFavorite
                    ? const Icon(Icons.favorite)
                    : const Icon(Icons.favorite_border),
              ),
            )
          ],
        );
      }).toList(),
    );
  }
}
