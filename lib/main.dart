import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixiv Func I18n Generator',
      home: const HomePage(),
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFFF6289),
        colorScheme: const ColorScheme.dark().copyWith(primary: const Color(0xFFFF6289)),
      ),
      themeMode: ThemeMode.dark,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final list = <KeyValueItem>[];

  bool hasError = false;

  @override
  void initState() {
    loadTemplateFile();
    super.initState();
  }

  CancelToken cancelToken = CancelToken();

  void loadTemplateFile() {
    cancelToken.cancel();
    cancelToken = CancelToken();
    setState(() {
      list.clear();
      hasError = false;
    });

    Dio()
        .get<String>('https://raw.githubusercontent.com/git-xiaocao/pixiv_func_mobile/new/lib/app/i18n/i18n_translations.dart', cancelToken: cancelToken)
        .then((response) {
      final tempList = decodeFile(response.data!);
      setState(() {
        list.addAll(tempList);
      });
    }).catchError((e) {
      if (e is DioError && e.type != DioErrorType.cancel) {
        setState(() {
          hasError = true;
        });
      }
    });
  }

  Future<void> copyToClipboard(String data) async {
    await Clipboard.setData(ClipboardData(text: data));
  }

  Future<String?> getClipboardData() async {
    return (await Clipboard.getData(Clipboard.kTextPlain))?.text;
  }

  void snackBar(String content) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(content), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixiv Func I18n Generator'),
        actions: [
          IconButton(
            onPressed: () {
              loadTemplateFile();
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: () {
        if (hasError) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: const Center(
              child: Text('加载模板失败,点击重试'),
            ),
          );
        } else {
          if (list.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          getClipboardData().then((text) {
                            if (text == null || text.isEmpty) {
                              snackBar('剪贴板为空');
                              return;
                            }
                            try {
                              final map = (jsonDecode(text) as Map<String, dynamic>);
                              for (final entry in map.entries) {
                                for (var item in list) {
                                  if (entry.key == item.jsonKey) {
                                    item.input.text = entry.value;
                                  }
                                }
                              }
                              snackBar('导入了${map.length}行');
                            } catch (e) {
                              snackBar('解析Json失败');
                            }
                          }).catchError((e) {
                            snackBar('导入失败');
                          });
                        },
                        child: const Text('从剪贴板导入(Json)'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () async {
                          getClipboardData().then((text) {
                            if (text == null || text.isEmpty) {
                              snackBar('剪贴板为空');
                              return;
                            }
                            final lines = decodeLines(text);
                            for (final line in lines) {
                              for (var item in list) {
                                if (line.name == item.name) {
                                  item.input.text = line.value;
                                }
                              }
                            }
                            snackBar('导入了${lines.length}行');
                          }).catchError((e) {
                            snackBar('导入失败');
                          });
                        },
                        child: const Text('从剪贴板导入(Dart)'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {
                          for (final item in list) {
                            if (item.input.text.isEmpty) {
                              snackBar('${item.name}为空');
                              return;
                            }
                          }
                          copyToClipboard(jsonEncode({}..addEntries(list.map((e) => MapEntry(e.jsonKey, e.input.text)))));
                        },
                        child: const Text('导出到剪贴板(Json)'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      showBottomBorder: true,
                      columns: const [
                        DataColumn(label: Text('Name', style: TextStyle(fontSize: 16))),
                        DataColumn(label: Text('zh_CN', style: TextStyle(fontSize: 16))),
                        DataColumn(label: Text('en_US', style: TextStyle(fontSize: 16))),
                        DataColumn(label: Text('Your Language', style: TextStyle(fontSize: 16))),
                      ],
                      rows: [
                        for (final item in list)
                          DataRow(cells: [
                            DataCell(SelectableText(item.name, style: const TextStyle(fontSize: 13, color: Colors.greenAccent))),
                            DataCell(SelectableText(item.zh, style: const TextStyle(fontSize: 13, color: Colors.orangeAccent))),
                            DataCell(SelectableText(item.en, style: const TextStyle(fontSize: 13, color: Colors.lightBlueAccent))),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: TextField(
                                  controller: item.input,
                                  minLines: 1,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        gapPadding: 1,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                                      constraints: const BoxConstraints(
                                        maxHeight: 50,
                                        minHeight: 50,
                                        maxWidth: 300,
                                      )),
                                ),
                              ),
                            ),
                          ])
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        }
      }(),
    );
  }
}

class KeyValueItem {
  final String name;
  final String zh;
  final String en;
  final TextEditingController input = TextEditingController();

  KeyValueItem(this.name, this.zh, this.en);

  String get jsonKey => name.substring(name.indexOf('.') + 1);
}

class LineItem {
  final String name;
  final String value;

  LineItem(this.name, this.value);
}

List<LineItem> decodeLines(String input) {
  final list = <LineItem>[];

  final lines = input.split('\n');
  for (final line in lines) {
    if (line.contains('I18n.')) {
      try {
        final name = line.substring(line.indexOf('I18n.'), line.indexOf(':'));
        final String value;
        if (line.contains(',')) {
          value = line.substring(line.indexOf('\'') + 1, line.indexOf(',') - 1);
        } else {
          value = line.substring(line.indexOf('\'') + 1, line.length - 2);
        }
        list.add(LineItem(name, value));
      } catch (e) {
        print(e);
      }
    }
  }

  return list;
}

List<KeyValueItem> decodeFile(String input) {
  final list = <KeyValueItem>[];

  const zhPrefix = '\'zh_CN\': {';
  const enPrefix = '\'en_US\': {';

  final zhStart = input.indexOf(zhPrefix) + zhPrefix.length;

  final zhEnd = input.indexOf('}', zhStart);

  final enStart = input.indexOf(enPrefix) + enPrefix.length;

  final enEnd = input.indexOf('}', enStart);

  final zh = input.substring(zhStart, zhEnd);

  final en = input.substring(enStart, enEnd);

  final zhLines = decodeLines(zh);

  final enLines = decodeLines(en);

  for (int i = 0; i < zhLines.length; ++i) {
    list.add(KeyValueItem(zhLines[i].name, zhLines[i].value, enLines[i].value));
  }

  return list;
}
