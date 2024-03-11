
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/app_widget_data.dart';
import 'package:immich_mobile/extensions/response_extensions.dart';
import 'package:immich_mobile/shared/models/asset.dart';
import 'package:immich_mobile/shared/providers/api.provider.dart';
import 'package:immich_mobile/shared/providers/db.provider.dart';
import 'package:immich_mobile/shared/providers/user.provider.dart';
import 'package:immich_mobile/shared/services/api.service.dart';
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
      ref.watch(favoriteAssetsListProvider),
      ref.watch(apiServiceProvider),
  );
});

class FavoritesWidgetService{
  final log = Logger("MemoryService");

  List<Asset> favoriteAssets;

  final ApiService _apiService;

  FavoritesWidgetService(this.favoriteAssets, this._apiService);

  void updateWidget() async {
    if (favoriteAssets.isEmpty){
      log.log(Level.INFO, 'No favorite assets');
      return;
    }
    Asset selectedAsset = favoriteAssets[0];

    var res = await _apiService.downloadApi
        .downloadFileWithHttpInfo(selectedAsset.remoteId!);

    if (res.statusCode != 200) {
      log.severe("Asset download failed", res.toLoggerString());
      return;
    }
    String path = "home_widget/${selectedAsset.fileName}";
      File targetFile = File(path);
      await targetFile.create();
      targetFile.writeAsBytes(res.bodyBytes, flush: true);
    log.log(Level.INFO, "Written file to $path");

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
