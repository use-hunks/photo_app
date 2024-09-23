import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photoapp/photo.dart';
import 'package:photoapp/photo_repository.dart';

// StreamProviderはStream(川の流れのような安定しないもの)を提供する
final userProvider = StreamProvider.autoDispose((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Providerは同期的な値を提供する。値が変化しないモノを渡す
final photoRepositoryProvider = Provider.autoDispose((ref) {
  final userAsyncValue = ref.watch(userProvider);
  return userAsyncValue.maybeWhen(
      data: (user) => user != null ? PhotoRepository(user) : null,
      orElse: () => null);
});

// ref.watch()を使うと他Providerのデータを取得できる
//　本の内容から変更した
final photoListProvider = StreamProvider.autoDispose((ref) {
  final photoRepository = ref.watch(photoRepositoryProvider);
  return photoRepository == null
      ? Stream.value(<Photo>[])
      : photoRepository.getPhotoList();
});

final favoritePhotoListProvider =
    FutureProvider.autoDispose<List<Photo>>((ref) async {
  try {
    final photoList = await ref.watch(photoListProvider.future);
    return photoList.where((photo) => photo.isFavorite == true).toList();
  } catch (e) {
    return [];
  }
});

// StateProviderは簡単な状態を管理する
final photoListIndexProvider = StateProvider.autoDispose((ref) {
  return 0;
});

//本の内容から変更した
// 値が変わらないのでProviderを利用
final photoViewInitialIndexProvider = Provider<int>((ref) {
  return 0;
});
