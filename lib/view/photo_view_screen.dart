import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photoapp/photo.dart';
import 'package:photoapp/providers.dart';
//import 'package:share_plus/share_plus.dart';

class PhotoViewScreen extends ConsumerStatefulWidget {
  const PhotoViewScreen({
    super.key,
  });

  @override
  PhotoViewScreenState createState() => PhotoViewScreenState();
}

class PhotoViewScreenState extends ConsumerState<PhotoViewScreen> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(photoViewInitialIndexProvider);
    _controller = PageController(initialPage: initialIndex);
  }

  //共有
  // FIXME: build errorを引き起こす。javaのバージョンのせいか？
  Future<void> _onTapShare() async {
    final photoList = ref.read(photoListProvider).value ?? [];
    final photo = photoList[_controller.page!.toInt()];
    //await Share.share(photo.imageURL);
  }

  //削除
  Future<void> _onTapDelete() async {
    final photoRepository = ref.read(photoRepositoryProvider);
    final photoList = ref.read(photoListProvider).value ?? [];
    final photo = photoList[_controller.page!.toInt()];

    if (photoList.length == 1) {
      Navigator.of(context).pop();
    } else if (photoList.last == photo) {
      await _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    await photoRepository!.deletePhoto(photo);
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("削除"),
        content: const Text("本当に写真を削除しますか？"),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () {
              _onTapDelete();
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //AppBarの裏までbodyの表示エリアを広げる
        extendBodyBehindAppBar: true,
        //透明なAppBar
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            Consumer(builder: (context, ref, child) {
              final asyncPhotoList = ref.watch(photoListProvider);
              return asyncPhotoList.when(
                  data: (photoList) {
                    return PageView(
                        controller: _controller,
                        children: photoList.map((Photo photo) {
                          return Image.network(
                            photo.imageURL,
                            fit: BoxFit.contain,
                          );
                        }).toList());
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, stackTrace) => Center(child: Text(e.toString())));
            }),
            //アイコンボタンを画像の手前に重ねる
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                  begin: FractionalOffset.bottomCenter,
                  end: FractionalOffset.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                )),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                          onPressed: _onTapShare,
                          color: Colors.white,
                          icon: const Icon(Icons.share)),
                      IconButton(
                          onPressed: () {
                            _showDeleteConfirmationDialog(context);
                          },
                          color: Colors.white,
                          icon: const Icon(Icons.delete))
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
