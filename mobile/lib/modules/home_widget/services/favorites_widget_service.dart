
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/app_widget_data.dart';
import 'package:immich_mobile/modules/asset_viewer/image_providers/immich_local_image_provider.dart';
import 'package:immich_mobile/modules/favorite/providers/favorite_provider.dart';
import 'package:immich_mobile/shared/models/asset.dart';
import 'package:immich_mobile/shared/providers/db.provider.dart';
import 'package:immich_mobile/shared/providers/user.provider.dart';
import 'package:immich_mobile/shared/services/api.service.dart';
import 'package:immich_mobile/shared/ui/immich_image.dart';
import 'package:immich_mobile/shared/ui/immich_thumbnail.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

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
  final log = Logger("MemoryService");

  List<Asset> favoriteAssets;
  final _globalKey = GlobalKey();

  FavoritesWidgetService(this.favoriteAssets);

  void updateWidget() async {
    if (favoriteAssets.isEmpty){
      log.log(Level.INFO, 'No favorite assets');
      return;
    }
    Asset selectedAsset = favoriteAssets[0];
    Widget imageWidget = ImageWidget(image: ImmichImage.imageProvider(
      asset: selectedAsset,
    )).build(_globalKey.currentContext!);
    log.log(Level.INFO, 'Selected asset: ${selectedAsset.name}');
    var path = await HomeWidget.renderFlutterWidget(
      imageWidget,
      key: 'filename',
      logicalSize: _globalKey.currentContext!.size!,
      pixelRatio:
      MediaQuery.of(_globalKey.currentContext!).devicePixelRatio,
    ) as String;
    log.log(Level.INFO, 'Widget rendered at $path');
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
