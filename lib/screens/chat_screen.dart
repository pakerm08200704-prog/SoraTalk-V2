import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:ruby_text/ruby_text.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ChatScreen(),
  ));
}

// --- 夥伴，這是整合後的全場景對話題庫 ---
final Map<String, List<Map<String, List<Map<String, String>>>>> dialogueData = {
  '🛒 購物': [
    {
      'lines': [
        {'role': 'A', 'japanese': 'いらっしゃいませ。何[なに]を お探[さが]しですか。', 'chinese': '歡迎光臨。請問在找什麼呢？'},
        {'role': 'B', 'japanese': 'これを 見[み]せて ください。', 'chinese': '請給我看這個。'},
        {'role': 'A', 'japanese': 'はい、どうぞ。', 'chinese': '好的，請。'},
      ]
    },
    {
      'lines': [
        {'role': 'B', 'japanese': '試着[しちゃく]して いいですか。', 'chinese': '可以試穿嗎？'},
        {'role': 'A', 'japanese': 'はい、あちらに 試着室[しちゃくしつ]が あります。', 'chinese': '好的，那邊有試穿室。'},
      ]
    },
  ],
  '🍱 點餐': [
    {
      'lines': [
        {'role': 'A', 'japanese': 'ご注文[ちゅうもん]は お決[き]まりですか。', 'chinese': '請問決定好餐點了嗎？'},
        {'role': 'B', 'japanese': 'これと これを ください。', 'chinese': '請給我這個和這個。'},
        {'role': 'A', 'japanese': 'かしこまりました。少々[しょうしょう] お待[ま]ちください。', 'chinese': '好的，我知道了。請稍等一下。'},
      ]
    },
  ],
  '💳 結帳': [
    {
      'lines': [
        {'role': 'B', 'japanese': 'お会計[かいけい]、お願[ねが]いします。', 'chinese': '麻煩結帳。'},
        {'role': 'A', 'japanese': '全部[ぜんぶ]で ５０００円[えん]です。', 'chinese': '總共是 5000 日圓。'},
        {'role': 'B', 'japanese': 'カードで 払[はら]えますか。', 'chinese': '可以用信用卡付錢嗎？'},
        {'role': 'A', 'japanese': 'はい、大丈夫[だいじょうぶ]ですよ。', 'chinese': '是的，沒問題。'},
      ]
    },
  ],
  '✈️ 機場': [
    {
      'lines': [
        {'role': 'A', 'japanese': 'パスポートを 見[み]せて ください。', 'chinese': '請出示護照。'},
        {'role': 'B', 'japanese': 'はい、どうぞ。', 'chinese': '好的，請。'},
        {'role': 'A', 'japanese': 'ご職業[しょくぎょう]は 何[なん]ですか。', 'chinese': '您的職業是什麼？'},
        {'role': 'B', 'japanese': '公務員[こうむいん]です。', 'chinese': '我是公務員。'},
      ]
    },
  ],
  '🏫 學校': [
    {
      'lines': [
        {'role': 'A', 'japanese': '宿題[しゅくだい]を 出[だ]して ください。', 'chinese': '請交作業。'},
        {'role': 'B', 'japanese': 'すみません、家[いえ]に 忘[わす]れました。', 'chinese': '對不起，我忘在家裡了。'},
        {'role': 'A', 'japanese': '明日[あした] 必[かなら]ず 持[も]って 来[き]て くださいね。', 'chinese': '明天請務必帶過來喔。'},
      ]
    },
  ],
  '🏠 居家': [
    {
      'lines': [
        {'role': 'B', 'japanese': 'ただいま。', 'chinese': '我回來了。'},
        {'role': 'A', 'japanese': 'お帰りなさい。ご飯[はん]の 前[まえ]に お風呂[ふろ]に しますか。', 'chinese': '回來了。飯前要先洗澡嗎？'},
        {'role': 'B', 'japanese': 'いいえ、先[さき]に ご飯[はん]を 食[た]べたいです。', 'chinese': '不，我想先吃飯。'},
      ]
    },
    {
      'lines': [
        {'role': 'B', 'japanese': 'いただきます。', 'chinese': '我要開動了。'},
        {'role': 'A', 'japanese': 'はい、召[め]し上[あ]がれ。', 'chinese': '好的，請享用。'},
        {'role': 'B', 'japanese': 'ごちそうさまでした。とても 美味[おい]しかったです。', 'chinese': '吃飽了。非常美味。'},
      ]
    },
  ],
};

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<_DialogueBlock> _dialogues = [];
  final ScrollController _scroll = ScrollController();
  final Random _rnd = Random();
  late final FlutterTts _tts;
  late final AudioRecorder _rec;
  late final AudioPlayer _play;
  bool _isRec = false;
  String? _recordingLineId;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _rec = AudioRecorder();
    _play = AudioPlayer();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("ja-JP");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  void _pickDialogue(String category) {
    final list = dialogueData[category]!;
    final pick = list[_rnd.nextInt(list.length)];
    final lines = pick['lines']!;
    final dialogueId = DateTime.now().millisecondsSinceEpoch.toString();
    
    setState(() {
      _dialogues.add(_DialogueBlock(
        id: dialogueId,
        category: category,
        lines: lines.map((l) => _DialogueLine(
          role: l['role']!,
          japanese: l['japanese']!,
          chinese: l['chinese']!,
        )).toList(),
      ));
    });
    _scrollToBottom();
  }

  Future<void> _handleLineMic(String dialogueId, int lineIndex) async {
    final lineId = '$dialogueId-$lineIndex';
    if (!_isRec) {
      final hasPermission = await _rec.hasPermission();
      if (!hasPermission) return;
      setState(() { _isRec = true; _recordingLineId = lineId; });
      await _rec.start(const RecordConfig(encoder: AudioEncoder.opus), path: '');
    } else {
      if (_recordingLineId != lineId) return;
      final p = await _rec.stop();
      setState(() { _isRec = false; _recordingLineId = null; });
      if (p != null) {
        Future.delayed(const Duration(milliseconds: 400), () async {
          await _play.play(kIsWeb ? UrlSource(p) : DeviceFileSource(p));
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('SoraTalk - 生活情境模擬', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            height: 65,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: dialogueData.keys.map((cat) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(cat, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  onSelected: (_) => _pickDialogue(cat),
                  backgroundColor: Colors.blue[50],
                  selected: false,
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _dialogues.length,
              itemBuilder: (context, i) => _buildDialogueBlock(_dialogues[i]),
            ),
          ),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildDialogueBlock(_DialogueBlock dialogue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dialogue.category != null)
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 8),
            child: Chip(label: Text(dialogue.category!, style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.blueGrey,),
          ),
        ...dialogue.lines.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;
          final isB = line.role == 'B';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: isB ? Colors.blueAccent : Colors.grey[400],
                  radius: 18,
                  child: Text(line.role, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RubyText(_parseRuby(line.japanese), style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500)),
                            const Divider(height: 16),
                            Text(line.chinese, style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Colors.blueAccent),
                            onPressed: () => _tts.speak(line.japanese.replaceAll(RegExp(r'\[.*?\]'), '')),
                          ),
                          if (isB)
                            IconButton(
                              icon: Icon(
                                _isRec && _recordingLineId == '${dialogue.id}-$index' ? Icons.stop : Icons.mic_none,
                                color: _isRec && _recordingLineId == '${dialogue.id}-$index' ? Colors.red : Colors.grey,
                              ),
                              onPressed: () => _handleLineMic(dialogue.id, index),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20,),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 35),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: Text(
        _isRec ? '🎤 錄音中...請對著麥克風唸出日文句子' : '請選擇上方分類啟動對話練習',
        textAlign: TextAlign.center,
        style: TextStyle(color: _isRec ? Colors.redAccent : Colors.grey, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<RubyTextData> _parseRuby(String text) {
    final RegExp reg = RegExp(r'([^\[\]\s]+)\[([^\[\]]+)\]|(\S+)|(\s+)');
    return reg.allMatches(text).map((m) {
      if (m.group(1) != null) return RubyTextData(m.group(1)!, ruby: m.group(2));
      return RubyTextData(m.group(3) ?? m.group(4) ?? '');
    }).toList();
  }

  @override
  void dispose() { _tts.stop(); _rec.dispose(); _play.dispose(); super.dispose(); }
}

class _DialogueBlock {
  final String id; final String? category; final List<_DialogueLine> lines;
  _DialogueBlock({required this.id, this.category, required this.lines});
}
class _DialogueLine {
  final String role; final String japanese; final String chinese;
  _DialogueLine({required this.role, required this.japanese, required this.chinese});
}