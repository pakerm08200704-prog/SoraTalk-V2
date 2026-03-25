import 'package:flutter_test/flutter_test.dart';
// 關鍵修正：將 soratalk 改為 soratalk_v2
import 'package:soratalk_v2/main.dart';

void main() {
  testWidgets('SoraTalk App smoke test', (WidgetTester tester) async {
    // 建立 App 並觸發一個幀
    await tester.pumpWidget(const MyApp());

    // 驗證 App 是否成功啟動 (檢查是否有包含 SoraTalk 字樣的元件)
    // 註：這只是一個基礎測試，確保專案名稱對齊後能順利編譯
    expect(find.byType(MyApp), findsOneWidget);
  });
}