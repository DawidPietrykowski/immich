
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/app_widget_data.dart';
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
  final _globalKey = GlobalKey();

  FavoritesWidgetService(this.favoriteAssets);

  void updateWidget() async {
    Asset selectedAsset = favoriteAssets[0];
    print('Selected asset: ${selectedAsset.name}');
    var path = await HomeWidget.renderFlutterWidget(
      ImageWidget(image: ImmichThumbnail.imageProvider(asset: selectedAsset),),
      key: 'filename',
      logicalSize: _globalKey.currentContext!.size!,
      pixelRatio:
      MediaQuery.of(_globalKey.currentContext!).devicePixelRatio,
    ) as String;
    HomeWidget.saveWidgetData<String>('filename', path);
    HomeWidget.updateWidget(
      iOSName: iOSWidgetName,
      androidName: androidWidgetName,
    );
  }
}


class ImageWidget extends StatelessWidget {
  const ImageWidget({
    super.key,
    required this.image,
  });

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Image(image: image);
  }
}
