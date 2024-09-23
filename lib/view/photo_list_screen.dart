import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photoapp/photo.dart';
import 'package:photoapp/photo_repository.dart';
import 'package:photoapp/providers.dart';
import 'package:photoapp/view/photo_view_screen.dart';
import 'package:photoapp/view/sign_in_screen.dart';

class PhotoListScreen extends ConsumerStatefulWidget {
  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends ConsumerState<PhotoListScreen> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: ref.read(photoListIndexProvider));
  }

  void _onPageChanged(int index) {
    //TODO: これどこの操作を表してる？？
    ref.read(photoListIndexProvider.notifier).state = index;
  }

  void _onTapBottomNavigatingItem(int index) {
    //PageViewで表示されているWidgetを切り替える
    _controller.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    ref.read(photoListIndexProvider.notifier).state = index;
  }

  void _onTapPhoto(Photo photo, List<Photo> photoList) {
    // TODO: あとでこの処理理解する
    final initialIndex = photoList.indexOf(photo);
    //最初に表示する画像のURLを指定して、画像詳細画面に切り替え
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProviderScope(overrides: [
              photoViewInitialIndexProvider.overrideWithValue(initialIndex)
            ], child: PhotoViewScreen())));
  }

  Future<void> _onSignOut() async {
    await FirebaseAuth.instance.signOut();
    //ログアウトに成功したらログイン画面に戻る
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SignInScreen(),
    ));
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

  @override
  Widget build(BuildContext context) {
    //ログインしているユーザーの情報を取得
    return Scaffold(
      appBar: AppBar(
        title: const Text("Photo App"),
        actions: [
          //ログアウトのボタンを右上に配置
          IconButton(
            onPressed: () => _onSignOut(),
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
                    onTap: (photo) => _onTapPhoto(photo, photoList),
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
                        onTap: (photo) => _onTapPhoto(photo, photoList),
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

  const PhotoGridView({
    Key? key,
    required this.photoList,
    required this.onTap,
    required this.onTapFav,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('PhotoList length: ${photoList.length}');
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
                onPressed: () => onTapFav(photo), //TODO: お気に入りボタンを押した後の処理
                color:  photo.isFavorite ? Colors.pink : Colors.white,
                icon: photo.isFavorite ? const Icon(Icons.favorite): const Icon(Icons.favorite_border),
              ),
            )
          ],
        );
      }).toList(), //CHECK: なぜ？
    );
  }
}
