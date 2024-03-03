
import 'dart:io';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/favorite/providers/favorite_provider.dart';
import 'package:immich_mobile/shared/models/asset.dart';
import 'package:immich_mobile/shared/providers/db.provider.dart';
import 'package:immich_mobile/shared/providers/user.provider.dart';
import 'package:immich_mobile/shared/services/api.service.dart';
import 'package:immich_mobile/shared/ui/immich_thumbnail.dart';
import 'package:isar/isar.dart';

final favoriteAssetsListProvider = Provider<List<Asset>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return List.empty();
  final query = ref
      .watch(dbProvider)
      .assets
      .where()
      .ownerIdEqualToAnyChecksum(user.isarId)
      .filter()
      .isFavoriteEqualTo(true)
      .isTrashedEqualTo(false)
      .sortByFileCreatedAtDesc();
  return query.build().findAllSync();
});


final favoritesWidgetServiceProvider = StateProvider<FavoritesWidgetService>((ref) {
  return FavoritesWidgetService(
    ref.watch(favoriteAssetsListProvider)
  );
});

class FavoritesWidgetService{
  List<Asset> favoriteAssets;

  FavoritesWidgetService(this.favoriteAssets);

  void updateWidget() {
    Asset selectedAsset = favoriteAssets[0];
    print('Selected asset: ${selectedAsset.name}');
    ImmichThumbnail.imageProvider(asset: selectedAsset)
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((info, call) {
      print('Image loaded');
      Image image = info.image;
      image.toByteData(format: ImageByteFormat.png).then((byteData) {
        print('Image byte data: ${byteData!.lengthInBytes}');
        File file = File('image.png');
        file.writeAsBytes(byteData.buffer.asUint8List()).then((value) {
          print('Image saved');
      });
    });}));
  }
}
