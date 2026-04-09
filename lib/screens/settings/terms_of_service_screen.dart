import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('利用規約'),
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SectionTitle('「ポイゴー」利用規約'),
            SizedBox(height: 8),
            _BodyText(
              '株式会社KeyGo（以下、「弊社」といいます。）は、歩行等の活動を通じてポイントを得るサービス'
              '「ポイゴー」（以下、「本サービス」といいます。）の利用に関し、以下のとおり利用規約を定めます。',
            ),
            SizedBox(height: 20),
            _KeyPointsCard(),
            SizedBox(height: 20),
            _ArticleTitle('第1条（適用）'),
            _BodyText(
              '本規約は、本サービスの利用および利用により得るポイント（以下、「チップ」といいます。）'
              'に関する諸条件を定めたものです。',
            ),
            SizedBox(height: 16),
            _ArticleTitle('第2条（使用条件）'),
            _BulletText('利用者は、自己の責任において本サービスを利用するものとします。'),
            _BulletText('アカウントの作成は1名の利用者につき1つまでとします。'),
            SizedBox(height: 16),
            _ArticleTitle('第3条（利用登録と本人確認）'),
            _BulletText('本サービスのご利用にあたり、メールアドレス等による登録が必要な場合があります。'),
            _BulletText(
              'チップを特典と交換する際、弊社は電話番号認証（SMS認証）による本人確認を求めるものとし、'
              '認証が完了しない場合は交換を行うことができません。',
            ),
            SizedBox(height: 16),
            _ArticleTitle('第4条（禁止事項）'),
            _BodyText('利用者は、以下の行為をしてはなりません。'),
            _BulletText('不正な手段（歩数偽装アプリの使用、デバイスの不正な操作等）によりチップを取得する行為。'),
            _BulletText('1人で複数のアカウントを保有する行為。'),
            _BulletText('その他、運営が不適切と判断する行為。'),
            SizedBox(height: 16),
            _ArticleTitle('第5条（チップの付与と交換）'),
            _BulletText(
              'チップは、歩数タンクの回収、動画広告の視聴、または提携パートナー（SKYFLAG等）の'
              '提供する条件達成により付与されます。',
            ),
            _BulletText('チップの換算レートは「100チップ＝1円相当」とします。'),
            _BulletText('チップの交換は、弊社所定の最低交換額（30,000チップ／300円分）から可能とします。'),
            _BulletText('チップの有効期限は、最後にチップを取得した日から180日間とします。期限を過ぎたチップは自動的に消去されます。'),
            SizedBox(height: 16),
            _ArticleTitle('第6条（免責事項）'),
            _BulletText('弊社は、通信回線、システム障害、外部サービス連携等に起因する損害について、弊社に故意または重過失がある場合を除き、責任を負いません。'),
            _BulletText('本サービスの全部または一部は、保守・障害対応・運営上の都合により、予告なく中断または停止される場合があります。'),
            SizedBox(height: 16),
            _ArticleTitle('第7条（規約変更）'),
            _BodyText(
              '弊社は、必要に応じて本規約を変更できるものとします。変更後の規約は、本サービス上への掲示または'
              '弊社が適当と判断する方法により利用者へ通知した時点から効力を生じるものとします。',
            ),
            SizedBox(height: 16),
            _ArticleTitle('第8条（準拠法および管轄裁判所）'),
            _BodyText(
              '本規約は日本法に準拠して解釈されるものとし、本サービスに関して紛争が生じた場合は、'
              '弊社本店所在地を管轄する裁判所を第一審の専属的合意管轄裁判所とします。',
            ),
            SizedBox(height: 20),
            _BodyText('制定日：2026年3月30日'),
            _BodyText('株式会社KeyGo'),
          ],
        ),
      ),
    );
  }
}

class _KeyPointsCard extends StatelessWidget {
  const _KeyPointsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '重要事項',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: 8),
          _KeyPointLine(label: '交換レート', value: '100チップ = 1円'),
          _KeyPointLine(label: '最低交換額', value: '30,000チップ（300円分）'),
          _KeyPointLine(label: '本人確認', value: '初回交換時のSMS認証が必須'),
          _KeyPointLine(label: '有効期限', value: '最終獲得から180日'),
        ],
      ),
    );
  }
}

class _KeyPointLine extends StatelessWidget {
  const _KeyPointLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
    );
  }
}

class _ArticleTitle extends StatelessWidget {
  const _ArticleTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('・', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
