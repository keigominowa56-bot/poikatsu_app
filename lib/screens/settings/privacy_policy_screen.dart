import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Title('「ポイゴー」プライバシーポリシー'),
            SizedBox(height: 10),
            _Body(
              '株式会社KeyGo（以下、「弊社」といいます。）は、歩行等の活動を通じてポイントを得るサービス'
              '「ポイゴー」（以下、「本サービス」といいます。）に関連して取得する個人情報および利用者情報を、'
              '本ポリシーに従って取り扱います。',
            ),
            SizedBox(height: 18),
            _EmphasisCard(),
            SizedBox(height: 18),
            _Section('第1条（個人情報の取扱い）'),
            _Body(
              '本サービスの利用にあたり弊社が取得する個人情報は、個人情報の保護に関する法律その他関係法令を遵守し、'
              '適正な方法で取得・利用・管理します。',
            ),
            _Body('アプリ配布プラットフォーム上で利用者が入力した情報は、各プラットフォーム運営者の規約・方針に従って管理されます。'),
            _Bullet('Google Play（Google LLC）'),
            _Bullet('App Store（Apple Inc.）'),
            _Body('弊社は、法令に基づく場合等を除き、本人の同意なく個人情報を第三者へ提供しません。'),
            SizedBox(height: 14),
            _Section('第2条（取得する利用者情報）'),
            _Body('弊社は、本サービス提供のため、以下の利用者情報を取得することがあります。'),
            _Bullet('メールアドレス、ログイン識別情報'),
            _Bullet('端末識別子（IDFA、AAID等）、端末情報（OS、言語、機種情報等）'),
            _Bullet('歩数等の健康・フィットネス情報（HealthKit / Google Fit / Health Connect 経由）'),
            _Bullet('広告視聴履歴、アプリ内行動履歴、アクセスログ'),
            _Bullet('アンケート回答情報（任意で回答された場合）'),
            SizedBox(height: 14),
            _Section('第3条（利用目的）'),
            _Body('取得した情報は、次の目的で利用します。'),
            _Bullet('本サービスの提供、本人確認、不正利用防止'),
            _Bullet('歩数・ミッション等に応じたチップ付与の判定と履歴管理'),
            _Bullet('お問い合わせ対応、重要なお知らせの配信'),
            _Bullet('機能改善、統計分析、品質向上、新機能検討'),
            _Bullet('広告配信の最適化および効果測定（法令および各プラットフォーム規約に従う）'),
            SizedBox(height: 14),
            _Section('第4条（第三者提供・外部送信）'),
            _Body(
              '弊社は、広告配信、アクセス解析、クラウド運用等のため、必要な範囲で外部事業者のサービスを利用することがあります。'
              'この場合、利用者情報は各事業者の規約・プライバシーポリシーに従って取り扱われます。',
            ),
            _Body('健康・フィットネス情報は、広告販売や再販を目的として第三者へ提供しません。'),
            SizedBox(height: 14),
            _Section('第5条（安全管理）'),
            _Body(
              '弊社は、漏えい、滅失または毀損の防止その他安全管理のため、アクセス制御、通信の保護、運用ルール整備等の'
              '合理的な安全管理措置を講じます。',
            ),
            SizedBox(height: 14),
            _Section('第6条（委託）'),
            _Body(
              '弊社は、利用目的の達成に必要な範囲で、利用者情報の取扱いを外部へ委託することがあります。'
              '委託先の選定および監督は適切に行います。',
            ),
            SizedBox(height: 14),
            _Section('第7条（開示・訂正・削除等）'),
            _Body(
              '利用者は、法令の定めに従い、自己の個人情報について開示、訂正、追加、削除、利用停止等を求めることができます。'
              '請求手続きは第10条のお問い合わせ窓口よりご連絡ください。',
            ),
            SizedBox(height: 14),
            _Section('第8条（オプトアウト）'),
            _Body('広告識別子や位置情報の取得は、端末設定またはアプリ設定により制限できる場合があります。'),
            _Body('ただし、設定によっては一部機能（歩数計測連携、最適化表示等）が利用できなくなることがあります。'),
            SizedBox(height: 14),
            _Section('第9条（改定）'),
            _Body(
              '弊社は、法令改正またはサービス内容変更に応じて、本ポリシーを改定することがあります。'
              '重要な変更は、アプリ内表示または弊社所定の方法で周知します。',
            ),
            SizedBox(height: 14),
            _Section('第10条（お問い合わせ窓口）'),
            _Body('利用者情報の取扱いに関するお問い合わせは、以下窓口までご連絡ください。'),
            _Body('株式会社KeyGo サポート窓口'),
            _Body('メール: support@keygo.jp'),
            SizedBox(height: 14),
            _Body('制定日：2026年3月30日'),
            _Body('株式会社KeyGo'),
          ],
        ),
      ),
    );
  }
}

class _EmphasisCard extends StatelessWidget {
  const _EmphasisCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
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
          Text('・歩数等の健康情報は、サービス提供に必要な範囲でのみ利用します。', style: TextStyle(fontSize: 13, height: 1.45)),
          Text('・健康情報を広告販売・再販目的で第三者提供しません。', style: TextStyle(fontSize: 13, height: 1.45)),
          Text('・本人確認や不正対策のために必要情報を利用します。', style: TextStyle(fontSize: 13, height: 1.45)),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textPrimary)),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('・', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
