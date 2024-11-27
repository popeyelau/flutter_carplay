import 'package:flutter_carplay/flutter_carplay.dart';

class FlutterCarplayHelper {
  CPListItem? findCPListItem({
    required List<dynamic> templates,
    required String elementId,
  }) {
    for (final template in templates) {
      final listTemplates = <CPListTemplate>[];
      if (template is CPTabBarTemplate) {
        listTemplates.addAll(template.templates);
      } else if (template is CPListTemplate) {
        listTemplates.add(template);
      }
      if (listTemplates.isNotEmpty) {
        for (final list in listTemplates) {
          for (final section in list.sections) {
            for (final item in section.items) {
              if (item.uniqueId == elementId) return item;
            }
          }
        }
      }
    }
    return null;
  }

  String makeFCPChannelId({String? event = ""}) =>
      'com.oguzhnatly.flutter_carplay${event!}';
}
