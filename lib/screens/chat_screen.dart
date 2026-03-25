import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: ChatScreen()));

// --- 曾夥伴優化版 (括號排版 + 讀音修正：曾[そう]) ---
final Map<String, List<Map<String, List<Map<String, String>>>>> dialogueData = {
  '🏨 住宿': [{'lines': [
    {'role': 'A', 'japanese': 'いらっしゃいませ。ご予約[よやく]の お名前[なまえ]を お願[ねが]いします。', 'chinese': '歡迎光臨。請告訴我您預約的姓名。'},
    {'role': 'B', 'japanese': '曾[そう]です。今日[きょう]から 三泊[さんぱく]で 予約[よやく]しました。', 'chinese': '我姓曾。我預約了從今天起住三晚。'},
    {'role': 'A', 'japanese': 'はい、確認[かくにん]いたしました。パスポート[ぱすぽーと]を 拝見[はいけん]します。', 'chinese': '好的，已經確認好了。請讓我看一下您的護照。'},
    {'role': 'B', 'japanese': 'はい、どうぞ。Wi-Fi[わいふぁい]の パスワード[ぱすわーど]は 這裡[どこ]に ありますか。', 'chinese': '好的，請。請問 Wi-Fi 密碼在哪裡呢？'},
    {'role': 'A', 'japanese': 'お部屋[おへや]の カードキー[かーどきー]に 書[か]いて あります。ごゆっくり どうぞ。', 'chinese': '寫在房間的房卡上。請慢用。'},
  ]}],
  '📍 問路': [{'lines': [
    {'role': 'A', 'japanese': 'こんにちは。何[なに]か お困[こま]りですか。', 'chinese': '妳好。有什麼困難嗎？'},
    {'role': 'B', 'japanese': 'はい。東京[とうきょう]タワー[たわー]へ 行[い]きたいですが、道[みち]を 教え[おしえ]て ください。', 'chinese': '是的。我想去東京鐵塔，請告訴我怎麼走。'},
    {'role': 'A', 'japanese': '真っ直ぐ[まっすぐ] 行[い]って、二[ふた]つ目[め]の 角[かど]を 左[ひだり]に 曲[ま]がって ください。', 'chinese': '請直走，在第二個轉角左轉。'},
    {'role': 'B', 'japanese': '左[ひだり]ですね。步[ある]いて どのくらい かかりますか。', 'chinese': '左轉對吧。走路大約要多久呢？'},
    {'role': 'A', 'japanese': '十分[じゅっぷん]くらいですよ。すぐ 分[わ]かりますよ。', 'chinese': '大約十分鐘喔。馬上就會找到了。'},
  ]}],
  '🏥 醫院': [{'lines': [
    {'role': 'A', 'japanese': 'どうしましたか。どこが 痛[いた]いですか。', 'chinese': '怎麼了呢？哪裡不舒服呢？'},
    {'role': 'B', 'japanese': '昨日[きのう]から 熱[ねつ]が あって、喉[のど]も 痛[いた]いです。', 'chinese': '從昨天開始發燒，喉嚨也很痛。'},
    {'role': 'A', 'japanese': 'そうですか。検査[けんさ]を しましょう。', 'chinese': '這樣啊。我們來做一下檢查吧。'},
    {'role': 'B', 'japanese': 'はい、お願[ねが]いします。強[つよ]い 薬[くすり]は 飲[の]みたくないです。', 'chinese': '好的，拜託了。我不想吃太強的藥。'},
    {'role': 'A', 'japanese': 'わかりました。弱[よわ]い 藥[くすり]を 出[だ]しますね。お大事[だいじ]に。', 'chinese': '明白了。我開比較溫和的藥給你。請保重。'},
  ]}],
  '⚡ 電器': [{'lines': [
    {'role': 'A', 'japanese': 'いらっしゃいませ。何[なに]か お探[さが]しですか。', 'chinese': '歡迎光臨。請問在找什麼呢？'},
    {'role': 'B', 'japanese': 'すみません、這個 炊飯器[すいはんき]を 買[か]いたいですが。', 'chinese': '不好意思，我想買這台電鍋。'},
    {'role': 'A', 'japanese': 'ありがとうございます。こちら、今[いま] 一番[いちばん] 人気[にんき]ですよ。', 'chinese': '謝謝。這一款是現在受歡迎的喔。'},
    {'role': 'B', 'japanese': '少[すこ]し 安[やす]く して もらえませんか。', 'chinese': '能不能再算便宜一點呢？'},
    {'role': 'A', 'japanese': '特別[とくべつ]に 五百円[ごひゃくえん] 引[び]きましょう。', 'chinese': '特別幫您折價 500 日圓吧。'},
  ]}],
  '🛒 購物': [{'lines': [
    {'role': 'A', 'japanese': 'いらっしゃいませ。お菓子[おかし]は いかがですか。', 'chinese': '歡迎光臨。要不要看看點心呢？'},
    {'role': 'B', 'japanese': 'あの、日本[にほん]の お土産[みやげ]を 探[さが]して います。', 'chinese': '那個，我正在找日本的伴手禮。'},
    {'role': 'A', 'japanese': 'こちらが おすすめです。一[ひと]つ 千円[せんえん]です。', 'chinese': '推薦這一款。一個一千日圓。'},
    {'role': 'B', 'japanese': 'プレゼント[ぷれぜんと]の 包装[ほうそう]も できますか。', 'chinese': '也可以提供禮物包裝嗎？'},
    {'role': 'A', 'japanese': 'はい、できますよ。少々[しょうしょう] お待[ま]ち ください。', 'chinese': '是的，可以喔。請稍等一下。'},
  ]}],
  '💳 結帳': [{'lines': [
    {'role': 'A', 'japanese': 'いらっしゃいませ。お会計[かいけい]、お願[ねが]いします。', 'chinese': '歡迎光臨。麻煩結帳。'},
    {'role': 'B', 'japanese': 'はい。カード[かーど]で 払[はら]っても いいですか。', 'chinese': '好的。可以用信用卡付錢嗎？'},
    {'role': 'A', 'japanese': 'はい、使[つか]えますよ。レシート[れしーと]は 必要[ひつよう]ですか。', 'chinese': '是的，可以使用喔。需要收據嗎？'},
    {'role': 'B', 'japanese': 'はい、お願[ねが]いします。袋[ふくろ]も 一[ひと]つ ください。', 'chinese': '是的，拜託了。也請給我一個袋子。'},
    {'role': 'A', 'japanese': '全部[ぜんぶ]で 四千五百円[よんせんごひゃくえん]です。', 'chinese': '總共是 4,500 日圓。'},
  ]}],
  '🍱 點餐': [{'lines': [
    {'role': 'A', 'japanese': 'いらっしゃいませ。ご注文[ちゅうもん]は お決[き]まりですか。', 'chinese': '歡迎光臨。請問決定好餐點了嗎？'},
    {'role': 'B', 'japanese': 'はい。ラーメン[らーめん] 二[ふた]つと 餃子[ぎょうざ]を お願[ね項]いします。', 'chinese': '是的。麻煩給我兩份拉麵和一份餃子。'},
    {'role': 'A', 'japanese': 'かしこまりました。お飲み物[のみもの]は いかがですか。', 'chinese': '我知道了。請問需要飲料嗎？'},
    {'role': 'B', 'japanese': 'いいえ、結構[けっこう]です。お水[おみず]を ください。', 'chinese': '不用了，謝謝。請給我白開水。'},
  ]}],
  '✈️ 機場': [{'lines': [
    {'role': 'A', 'japanese': '次[つぎ]の 方[かた]、どうぞ。入国[にゅうこく]の 目的[もくてき]は 何[なん]ですか。', 'chinese': '下一位請。入境目的是什麼？'},
    {'role': 'B', 'japanese': '観光[かんこう]です。五日間[いつかかん] 滞在[たいざい]します。', 'chinese': '是觀光。會停留五天。'},
    {'role': 'A', 'japanese': 'どこに 泊[と]まりますか。', 'chinese': '要住在哪裡呢？'},
    {'role': 'B', 'japanese': '新宿[しんじゅく]の ホテル[ほてる]です。', 'chinese': '新宿的飯店。'},
    {'role': 'A', 'japanese': 'はい、わかりました。良[よ]い 旅[たび]を。', 'chinese': '好的，明白了。祝您旅途愉快。'},
  ]}],
  '🏫 學校': [{'lines': [
    {'role': 'A', 'japanese': '曾[そう]さん、昨日[きのう]の 宿題[しゅくだい]を 出[だ]して ください。', 'chinese': '曾先生，請交昨天的作業。'},
    {'role': 'B', 'japanese': '先生[せんせい]、すみません。家[いえ]に 忘[わす]れて しまいました。', 'chinese': '老師，對不起。我不小心忘在家裡了。'},
    {'role': 'A', 'japanese': '困[こま]りましたね。今日[きょう]の 午後[ごご] 持[も]って 來[き]て ください。', 'chinese': '這下麻煩了呢。請今天下午帶過來。'},
    {'role': 'B', 'japanese': 'はい、わかりました。休み時間[やすみじかん]に 取[と]りに 帰り[かえ]ります。', 'chinese': '是的，我明白了。我休息時間回去拿。'},
  ]}],
  '🏠 居家': [{'lines': [
    {'role': 'A', 'japanese': 'お帰りなさい。今日[きょう]は 仕事[しごと]が 大變[たいへん]でしたか。', 'chinese': '你回來了。今天工作很辛苦嗎？'},
    {'role': 'B', 'japanese': 'ただいま。お腹[おなか]が ぺこぺこです。晩[ばん]ご飯[ごはん]は 何[なに]ですか。', 'chinese': '我回來了。肚子好餓喔。晚餐是什麼？'},
    {'role': 'A', 'japanese': '今日[きょう]は カレー[かれー]ですよ。もう すぐ 出來[でき]ます。', 'chinese': '今天吃咖哩喔。馬上就好了。'},
    {'role': 'B', 'japanese': 'やった！いい 匂[にお]いが しますね。', 'chinese': '太棒了！聞起來好香。'},
  ]}],
};

final Map<String, IconData> categoryIcons = {
  '🏨 住宿': Icons.hotel, '📍 問路': Icons.map, '🏥 醫院': Icons.local_hospital, '⚡ 電器': Icons.electrical_services,
  '🛒 購物': Icons.shopping_bag, '💳 結帳': Icons.payments, '🍱 點餐': Icons.restaurant, '✈️ 機場': Icons.flight_takeoff,
  '🏫 學校': Icons.school, '🏠 居家': Icons.home,
};

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  _DialogueBlock? _currentDialogue;
  late final FlutterTts _tts;
  late final AudioRecorder _rec;
  late final AudioPlayer _play;
  bool _isRec = false;
  String? _recordingLineId;
  final List<double> _speeds = [0.2, 0.4, 0.6, 0.8, 1.0, 1.2];
  int _speedIndex = 2;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts(); _rec = AudioRecorder(); _play = AudioPlayer();
    _initTts();
    _pickDialogue('🏨 住宿');
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("ja-JP");
    await _tts.setSpeechRate(_speeds[_speedIndex]);
  }

  void _cycleSpeed() {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
    _tts.setSpeechRate(_speeds[_speedIndex]);
  }

  void _pickDialogue(String category) {
    final list = dialogueData[category]!;
    setState(() {
      _currentDialogue = _DialogueBlock(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: category,
        lines: list[0]['lines']!.map((l) => _DialogueLine(role: l['role']!, japanese: l['japanese']!, chinese: l['chinese']!)).toList(),
      );
    });
  }

  Future<void> _handleLineMic(int index) async {
    final lineId = '${_currentDialogue!.id}-$index';
    if (!_isRec) {
      if (await _rec.hasPermission()) {
        setState(() { _isRec = true; _recordingLineId = lineId; });
        await _rec.start(const RecordConfig(), path: '');
      }
    } else {
      if (_recordingLineId != lineId) return;
      final path = await _rec.stop();
      setState(() { _isRec = false; _recordingLineId = null; });
      if (path != null) {
        Future.delayed(const Duration(milliseconds: 300), () => _play.play(kIsWeb ? UrlSource(path) : DeviceFileSource(path)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('SoraTalk：日語會話隨身教室', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0.5, centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: OutlinedButton.icon(
                onPressed: _cycleSpeed, icon: const Icon(Icons.speed, size: 16),
                label: Text('語速 ${_speeds[_speedIndex]}x', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent, side: const BorderSide(color: Colors.blueAccent, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              children: _currentDialogue!.lines.asMap().entries.map((e) => _buildLine(e.key, e.value)).toList(),
            ),
          ),
          _buildStatusFooter(),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 95, color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: categoryIcons.entries.map((entry) {
          final isSelected = _currentDialogue?.category == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
              onTap: () => _pickDialogue(entry.key),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isSelected ? Colors.blueAccent : Colors.grey[100], shape: BoxShape.circle),
                    child: Icon(entry.value, color: isSelected ? Colors.white : Colors.blueGrey[400], size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(entry.key.split(' ')[1], style: TextStyle(fontSize: 11, color: isSelected ? Colors.blueAccent : Colors.blueGrey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLine(int index, _DialogueLine line) {
    final isB = line.role == 'B';
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: isB ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isB) _buildAvatar('教練'),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: isB ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isB ? const Color(0xFFE3F2FD) : Colors.white,
                    borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: isB ? const Radius.circular(16) : Radius.zero, bottomRight: isB ? Radius.zero : const Radius.circular(16)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOptimizedRuby(line.japanese),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                      Text(line.chinese, style: const TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.4)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.volume_up, color: Colors.blueAccent, size: 20), onPressed: () => _tts.speak(line.japanese.replaceAll(RegExp(r'\[.*?\]'), ''))),
                    IconButton(icon: Icon(_isRec && _recordingLineId == '${_currentDialogue!.id}-$index' ? Icons.stop_circle : Icons.mic_none, color: Colors.redAccent, size: 20), onPressed: () => _handleLineMic(index)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isB) _buildAvatar('夥伴'),
        ],
      ),
    );
  }

  // --- 關鍵優化：括號排版函數 ---
  Widget _buildOptimizedRuby(String text) {
    final RegExp reg = RegExp(r'([^\[\]\s]+)\[([^\[\]]+)\]|([^\[\]\s]+)');
    List<TextSpan> spans = [];

    for (var m in reg.allMatches(text)) {
      if (m.group(1) != null) {
        // 漢字部分
        spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontSize: 17, color: Colors.black87, fontWeight: FontWeight.w500)));
        // 括號讀音部分 (縮小字體並改色)
        spans.add(TextSpan(text: '(${m.group(2)})', style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.normal)));
      } else if (m.group(3) != null) {
        // 一般假名或標點
        spans.add(TextSpan(text: m.group(3), style: const TextStyle(fontSize: 17, color: Colors.black87)));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      softWrap: true,
    );
  }

  Widget _buildAvatar(String label) {
    return CircleAvatar(radius: 15, backgroundColor: label == '教練' ? Colors.orange[50] : Colors.blue[50], child: Text(label[0], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: label == '教練' ? Colors.orange[800] : Colors.blue[800])));
  }

  Widget _buildStatusFooter() {
    return Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 35), color: Colors.white, child: Center(child: Text(_isRec ? '🎤 錄音中... 請模仿發音' : '💡 提示：A 為教練發話，B 為夥伴回應。', style: TextStyle(color: _isRec ? Colors.red : Colors.blueGrey[300], fontWeight: FontWeight.bold, fontSize: 11))));
  }

  @override
  void dispose() { _tts.stop(); _rec.dispose(); _play.dispose(); super.dispose(); }
}

class _DialogueBlock { final String id; final String category; final List<_DialogueLine> lines; _DialogueBlock({required this.id, required this.category, required this.lines}); }
class _DialogueLine { final String role; final String japanese; final String chinese; _DialogueLine({required this.role, required this.japanese, required this.chinese}); }