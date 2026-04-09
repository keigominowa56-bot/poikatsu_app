import 'package:flutter/material.dart';
import 'package:poigo/models/lottery_draw_model.dart';
import 'package:poigo/models/lottery_ticket_model.dart';
import 'package:poigo/services/lottery_service.dart';
import 'package:poigo/theme/app_colors.dart';
import 'package:poigo/widgets/video_reward_dialog.dart';

class MyLotteryScreen extends StatelessWidget {
  const MyLotteryScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('マイくじ', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<List<LotteryTicket>>(
        stream: LotteryService.instance.streamMyTickets(uid),
        builder: (context, snap) {
          final tickets = snap.data ?? [];
          if (tickets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.confirmation_number_rounded, size: 56, color: AppColors.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('まだチケットがありません', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('動画を見て宝くじチケットをもらおう', style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withOpacity(0.8))),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final t = tickets[index];
              return _TicketRow(uid: uid, ticket: t);
            },
          );
        },
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.uid, required this.ticket});
  final String uid;
  final LotteryTicket ticket;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LotteryDraw?>(
      stream: LotteryService.instance.streamDraw(ticket.round),
      builder: (context, drawSnap) {
        final draw = drawSnap.data;
        final result = _judge(ticket, draw);
        final canClaim = result.isWin && result.prize > 0 && !ticket.prizeClaimed;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryYellow.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.confirmation_number_rounded, color: AppColors.navy, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('第${ticket.round}回', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '${ticket.group}組 ${ticket.number}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.label,
                          style: TextStyle(fontSize: 12, color: result.isWin ? AppColors.primaryOrange : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (result.isWin)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: AppColors.primaryOrange),
                        const SizedBox(height: 2),
                        Text(
                          '+${result.prize} チップ',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy),
                        ),
                        if (ticket.prizeClaimed)
                          Text('受け取り済み', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    )
                  else
                    Text(draw == null ? '未発表' : 'はずれ', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              if (canClaim) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _claimPrizeWithVideo(context, uid, ticket, result.prize),
                    icon: const Icon(Icons.play_circle_filled, size: 20),
                    label: const Text('動画を見てチップを受け取る'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _claimPrizeWithVideo(BuildContext context, String uid, LotteryTicket ticket, int prize) {
    showVideoRewardDialog(
      context: context,
      title: '当選チップを受け取る',
      subtitle: '動画を最後まで視聴すると${prize}チップが付与されます。',
      onComplete: () async {
        final ok = await LotteryService.instance.claimPrize(ticket.id, uid, prize);
        if (!context.mounted) return;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${prize}チップを受け取りました！')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('受け取りに失敗しました。もう一度お試しください。')),
          );
        }
      },
    );
  }

  _TicketJudgeResult _judge(LotteryTicket ticket, LotteryDraw? draw) {
    if (draw == null) return const _TicketJudgeResult(label: '結果未発表', isWin: false, prize: 0);
    if (ticket.group == draw.winningGroup && ticket.number == draw.winningNumber) {
      return _TicketJudgeResult(label: '1等 当選！', isWin: true, prize: draw.prizeFirst);
    }
    if (ticket.number == draw.winningNumber) {
      return _TicketJudgeResult(label: '2等 当選！', isWin: true, prize: draw.prizeSecond);
    }
    if (ticket.number.length >= 4 && draw.winningNumber.length >= 4 && ticket.number.substring(2) == draw.winningNumber.substring(2)) {
      return _TicketJudgeResult(label: '3等 当選！', isWin: true, prize: draw.prizeThird);
    }
    return const _TicketJudgeResult(label: '結果発表済み', isWin: false, prize: 0);
  }
}

class _TicketJudgeResult {
  const _TicketJudgeResult({required this.label, required this.isWin, required this.prize});
  final String label;
  final bool isWin;
  final int prize;
}

