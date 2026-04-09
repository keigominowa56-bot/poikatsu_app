import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class TokushohoScreen extends StatelessWidget {
  const TokushohoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('特定商取引法に基づく表示'),
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Heading('「特定商取引に関する法律」第11条に基づき、以下のとおり表示します。'),
            SizedBox(height: 16),
            _Item(title: '販売事業者', body: '株式会社KeyGo'),
            _Item(title: '所在地', body: '〒150-0021\n東京都渋谷区恵比寿西二丁目8番4号 EX恵比寿西ビル5階'),
            _Item(title: '代表者', body: '箕輪圭剛'),
            _Item(title: 'お問い合わせ先', body: 'support@keygo.jp\n※平日10:00-17:00（土日祝除く）'),
            _Item(title: '販売価格', body: 'アプリ内または関連ページに表示する各商品・交換メニューの表示価格（税込）'),
            _Item(title: '販売価格以外で発生する費用', body: 'インターネット接続料金、通信料金等はお客様のご負担となります。'),
            _Item(title: 'お支払方法', body: '各決済画面に表示する方法に従います。'),
            _Item(title: 'サービス提供時期', body: '所定の手続き完了後、直ちに提供します。'),
            _Item(
              title: '返品・キャンセル',
              body: 'デジタルコンテンツの性質上、購入・交換確定後のキャンセル、返品、返金は原則としてお受けできません。'
                  '\nただし、法令上必要な場合はこの限りではありません。',
            ),
            _Item(
              title: '不良品・表示不具合',
              body: '交換済み特典コード等が利用できない場合は、確認のうえ代替手段の提示または再発行等、合理的な範囲で対応します。',
            ),
            _Item(
              title: '動作環境',
              body: '本サービスが対応するOSおよび端末は、アプリストア記載または弊社が別途定める環境に準じます。',
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.w600, color: AppColors.navy),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.navy.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
