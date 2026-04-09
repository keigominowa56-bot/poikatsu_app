import 'package:flutter/material.dart';
import 'package:poigo/data/jma_area_list.dart';
import 'package:poigo/models/jma_forecast_model.dart';
import 'package:poigo/constants/point_constants.dart';
import 'package:poigo/services/ad_service.dart';
import 'package:poigo/services/jma_forecast_service.dart';
import 'package:poigo/services/user_firestore_service.dart';
import 'package:poigo/theme/app_colors.dart';

/// 最高・最低気温を必ず正しい順（最高≧最低）で表示する
String _formatTempRange(int? max, int? min) {
  if (max == null && min == null) return '';
  if (max != null && min != null) {
    final high = max >= min ? max : min;
    final low = max <= min ? max : min;
    return '最高${high}°C / 最低${low}°C';
  }
  final v = max ?? min;
  return v != null ? '${v}°C' : '';
}

/// 天気キーと assets/weather/ の画像対応（気象庁コード・自作画像）
String weatherAssetPath(String key) {
  switch (key) {
    case 'sunny':
      return 'assets/weather/sunny.png';
    case 'heavy_sunny':
      return 'assets/weather/heavy_sunny.png';
    case 'cloudy':
      return 'assets/weather/cloudy.png';
    case 'rain':
      return 'assets/weather/rain.png';
    case 'heavy_rain':
      return 'assets/weather/heavy_rain.png';
    case 'rain_heavy':
      return 'assets/weather/rain_heavy.png';
    case 'rain_light':
      return 'assets/weather/rain_light.png';
    case 'snow':
      return 'assets/weather/snow.png';
    case 'heavy_snow':
      return 'assets/weather/heavy_snow.png';
    case 'thunder':
      return 'assets/weather/thunder.png';
    default:
      return 'assets/weather/sunny.png';
  }
}

/// 天気タブ: 気象庁JSONで「今日・明日・明後日」+ 地図、その下に週間予報リスト
class JapanWeatherTab extends StatefulWidget {
  const JapanWeatherTab({super.key, this.uid});

  final String? uid;

  @override
  State<JapanWeatherTab> createState() => _JapanWeatherTabState();
}

class _JapanWeatherTabState extends State<JapanWeatherTab> {
  String? _selectedAreaCode;
  bool _loading = true;
  JmaForecastResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    if (widget.uid == null || widget.uid!.isEmpty) {
      if (mounted) {
        setState(() => _selectedAreaCode ??= '130000');
        await _fetch();
      }
      return;
    }
    final user = await UserFirestoreService.instance.getUserOnce(widget.uid!);
    if (mounted) {
      setState(() {
        _selectedAreaCode ??= (user?.weatherAreaCode != null && user!.weatherAreaCode!.isNotEmpty)
            ? user.weatherAreaCode!
            : jmaAreaCodeFromPrefecture(user?.prefecture);
      });
      await _fetch();
    }
  }

  Future<void> _fetch() async {
    final code = _selectedAreaCode ?? '130000';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await JmaForecastService.instance.fetchForecast(code);
      if (mounted) setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _result = null;
        _loading = false;
      });
    }
  }

  void _onAreaSelected(String? code) {
    if (code == null || code == _selectedAreaCode) return;
    setState(() => _selectedAreaCode = code);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryOrange),
            SizedBox(height: 16),
            Text('天気を取得中…', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    if (_error != null || _result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                _error ?? '天気データを取得できませんでした',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('再取得'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.navy,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showAreaPicker(context),
                icon: const Icon(Icons.place_rounded, size: 18),
                label: const Text('地域を変更'),
                style: TextButton.styleFrom(foregroundColor: AppColors.navy),
              ),
            ],
          ),
        ),
      );
    }
    return _buildContent(context, _result!);
  }

  Widget _buildContent(BuildContext context, JmaForecastResult result) {
    final three = result.threeDay;
    final today = three.isNotEmpty ? three[0] : null;
    final tomorrow = three.length > 1 ? three[1] : null;
    final dayAfter = three.length > 2 ? three[2] : null;

    final areaMatches = jmaAreaList.where((a) => a.code == _selectedAreaCode).toList();
    final selectedArea = areaMatches.isNotEmpty ? areaMatches.first : jmaAreaList.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '天気予報',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showAreaPicker(context),
                icon: const Icon(Icons.place_rounded, size: 18),
                label: Text(selectedArea.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          if (result.areaName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '（${result.areaName}）',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          if (today != null) ...[
            Text(
              '現在の天気（今日）',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(today.dateLabel, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _WeatherIcon(weatherKey: today.toAssetKey(), size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    today.weatherText,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _tempText(today.tempMax, today.tempMin),
                                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/map/map.png',
                      fit: BoxFit.contain,
                      height: 120,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: AppColors.surface,
                        child: const Center(child: Icon(Icons.map_rounded, color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (tomorrow != null || dayAfter != null) ...[
              Text(
                '明日・明後日',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              if (tomorrow != null)
                _JmaDayTile(item: tomorrow),
              if (dayAfter != null) _JmaDayTile(item: dayAfter),
              const SizedBox(height: 24),
            ],
          ],
          _buildVideoChipButton(context),
          const SizedBox(height: 20),
          Text(
            '週間予報',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          ...result.weekly.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _JmaWeeklyTile(item: item),
              )),
        ],
      ),
    );
  }

  String _tempText(int? max, int? min) {
    if (max == null && min == null) return '';
    if (max != null && min != null) {
      final high = max >= min ? max : min;
      final low = max <= min ? max : min;
      return '最高 ${high}°C / 最低 ${low}°C';
    }
    if (max != null) return '${max}°C';
    return '${min}°C';
  }

  Widget _buildVideoChipButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_filled_rounded, size: 40, color: AppColors.primaryOrange),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('天気をチェックしてチップGET', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  '動画を見て${PointConstants.formatChips(PointConstants.admobRewardChipsPerView)}チップをもらう',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _showWeatherRewardVideo(context),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('動画を見る'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showWeatherRewardVideo(BuildContext context) async {
    final uid = widget.uid;
    if (uid == null || uid.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ログイン後にご利用ください')));
      }
      return;
    }
    await AdService.showRewardAd(
      context: context,
      onComplete: () async {
        await UserFirestoreService.instance.grantChips(uid, PointConstants.admobRewardChipsPerView, '天気チェック');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${PointConstants.formatChips(PointConstants.admobRewardChipsPerView)}チップを獲得しました！',
              ),
            ),
          );
        }
      },
      onFallback: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('広告の準備ができていません。しばらくしてからお試しください')));
      },
      onDismissed: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('動画を最後まで見るとチップがもらえます')));
      },
    );
  }

  void _showAreaPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('地域を選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: jmaAreaList.length,
                  itemBuilder: (_, i) {
                    final area = jmaAreaList[i];
                    final isSelected = area.code == _selectedAreaCode;
                    return ListTile(
                      title: Text(area.displayName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null, color: AppColors.textPrimary)),
                      subtitle: Text(area.name, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      selected: isSelected,
                      selectedTileColor: AppColors.primaryYellow.withOpacity(0.2),
                      onTap: () {
                        _onAreaSelected(area.code);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final code = _selectedAreaCode;
                      if (code == null || widget.uid == null || widget.uid!.isEmpty) {
                        Navigator.pop(ctx);
                        return;
                      }
                      await UserFirestoreService.instance.saveWeatherAreaCode(widget.uid!, code);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('My地域に登録しました')));
                        Navigator.pop(ctx);
                      }
                    },
                    icon: const Icon(Icons.bookmark_rounded, size: 20),
                    label: const Text('この地域をMy地域に登録'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: BorderSide(color: AppColors.primaryOrange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JmaDayTile extends StatelessWidget {
  const _JmaDayTile({required this.item});
  final JmaThreeDayItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textSecondary.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            _WeatherIcon(weatherKey: item.toAssetKey(), size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.dateLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.weatherText}  ${_formatTempRange(item.tempMax, item.tempMin)}',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JmaWeeklyTile extends StatelessWidget {
  const _JmaWeeklyTile({required this.item});
  final JmaWeeklyItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          _WeatherIcon(weatherKey: item.toAssetKey(), size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dateLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTempRange(item.tempMax, item.tempMin)}${item.pop != null && item.pop!.isNotEmpty ? "  降水${item.pop}%" : ""}'.trim(),
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  const _WeatherIcon({required this.weatherKey, this.size = 32});
  final String weatherKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = weatherAssetPath(weatherKey);
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.wb_sunny_rounded, size: size, color: AppColors.primaryOrange.withOpacity(0.8)),
    );
  }
}
