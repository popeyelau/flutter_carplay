import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_carplay/helpers/carplay_helper.dart';
import 'package:flutter_carplay/constants/private_constants.dart';

/// [FlutterCarPlayController] is an root object in order to control and communication
/// system with the Apple CarPlay and native functions.
class FlutterCarPlayController {
  static final FlutterCarplayHelper _carplayHelper = FlutterCarplayHelper();
  static final MethodChannel _methodChannel =
      MethodChannel(_carplayHelper.makeFCPChannelId());
  static final EventChannel _eventChannel =
      EventChannel(_carplayHelper.makeFCPChannelId(event: "/event"));

  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate], [CPIInformationTemplate], [CPPointOfInterestTemplate] in a List
  static List<dynamic> templateHistory = [];

  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate], [CPIInformationTemplate], [CPPointOfInterestTemplate]
  static dynamic currentRootTemplate;

  /// [CPAlertTemplate], [CPActionSheetTemplate]
  static dynamic currentPresentTemplate;

  /// Specific objects that are waiting to receive callback.
  static List<dynamic> callbackObjects = [];

  MethodChannel get methodChannel => _methodChannel;

  EventChannel get eventChannel => _eventChannel;

  /// Invokes the method channel with the specified [type] and [data]
  Future<bool> reactToNativeModule(FCPChannelTypes type, dynamic data) async {
    final value = await _methodChannel.invokeMethod(
        CPEnumUtils.stringFromEnum(type.toString()), data);
    return value;
  }

  /// Updates the [CPListItem]
  static void updateCPListItem(CPListItem updatedListItem) {
    _methodChannel
        .invokeMethod(
      FCPChannelTypes.updateListItem.name,
      updatedListItem.toJson(),
    )
        .then((value) {
      if (value) {
        for (final template in templateHistory) {
          switch (template) {
            case final CPTabBarTemplate tabBarTemplate:
              for (final (tabIndex, tab) in tabBarTemplate.templates.indexed) {
                for (final (sectionIndex, section) in tab.sections.indexed) {
                  for (final (itemIndex, item) in section.items.indexed) {
                    if (item.uniqueId == updatedListItem.uniqueId) {
                      tabBarTemplate.templates[tabIndex].sections[sectionIndex]
                          .items[itemIndex] = updatedListItem;
                      return;
                    }
                  }
                }
              }
            case final CPListTemplate listTemplate:
              for (final (sectionIndex, section)
                  in listTemplate.sections.indexed) {
                for (final (itemIndex, item) in section.items.indexed) {
                  if (item.uniqueId == updatedListItem.uniqueId) {
                    listTemplate.sections[sectionIndex].items[itemIndex] =
                        updatedListItem;
                    return;
                  }
                }
              }
            default:
          }
        }
      }
    });
  }

  void addTemplateToHistory(dynamic template) {
    if (template.runtimeType == CPTabBarTemplate ||
        template.runtimeType == CPGridTemplate ||
        template.runtimeType == CPInformationTemplate ||
        template.runtimeType == CPPointOfInterestTemplate ||
        template.runtimeType == CPListTemplate) {
      templateHistory.add(template);
    } else {
      throw TypeError();
    }
  }

  void processFCPListItemImageSelectedChannel(String elementId, int index) {
    final listItem = _carplayHelper.findCPListItem(
      templates: templateHistory,
      elementId: elementId,
    );
    if (listItem != null) {
      listItem.onImagePress!(
        () {},
        listItem,
        index,
      );
    }
  }

  void processFCPListItemSelectedChannel(String elementId) {
    final listItem = _carplayHelper.findCPListItem(
      templates: templateHistory,
      elementId: elementId,
    );
    if (listItem != null) {
      listItem.onPressed!(
        () => reactToNativeModule(
          FCPChannelTypes.onFCPListItemSelectedComplete,
          listItem.uniqueId,
        ),
        listItem,
      );
    }
  }

  /// Processes the FCPAlertActionPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPAlertAction]
  void processFCPAlertActionPressed(String elementId) {
    if (currentPresentTemplate is! CPActionSheetTemplate &&
        currentPresentTemplate is! CPAlertTemplate) return;

    final selectedAlertAction = switch (currentPresentTemplate) {
      final CPAlertTemplate template =>
        template.actions.singleWhereOrNull((e) => e.uniqueId == elementId),
      final CPActionSheetTemplate template =>
        template.actions.singleWhereOrNull((e) => e.uniqueId == elementId),
      _ => null,
    };

    selectedAlertAction?.onPress();
  }

  /// Processes the FCPAlertTemplateCompletedChannel
  ///
  /// Parameters:
  /// - completed: Whether the alert was successfully presented
  void processFCPAlertTemplateCompleted({bool completed = false}) {
    if (currentPresentTemplate is! CPAlertTemplate) return;
    (currentPresentTemplate as CPAlertTemplate).onPresent?.call(completed);
  }

  /// Processes the FCPGridButtonPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPGridButton]
  void processFCPGridButtonPressed(String elementId) {
    for (final template in templateHistory) {
      if (template is CPGridTemplate) {
        final button = template.buttons.singleWhereOrNull(
          (e) => e.uniqueId == elementId,
        );
        if (button != null) {
          button.onPress();
          return;
        }
      }
    }
  }

  /// Processes the FCPBarButtonPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPBarButton]
  void processFCPBarButtonPressed(String elementId) {
    for (final template in templateHistory) {
      if (template is CPListTemplate) {
        final backButton = template.backButton;
        if (backButton != null && backButton.uniqueId == elementId) {
          backButton.onPressed();
          return;
        }

        final button = template.leadingNavigationBarButtons.singleWhereOrNull(
              (e) => e.uniqueId == elementId,
            ) ??
            template.trailingNavigationBarButtons.singleWhereOrNull(
              (e) => e.uniqueId == elementId,
            );
        if (button != null) {
          button.onPressed();
          return;
        }
      }
    }
  }

  /// Processes the FCPTextButtonPressedChannel
  ///
  /// Parameters:
  /// - elementId: The id of the [CPTextButton]
  void processFCPTextButtonPressed(String elementId) {
    l1:
    for (final template in templateHistory) {
      if (template is CPPointOfInterestTemplate) {
        for (final p in template.poi) {
          if (p.primaryButton != null &&
              p.primaryButton!.uniqueId == elementId) {
            p.primaryButton!.onPressed();
            break l1;
          }
          if (p.secondaryButton != null &&
              p.secondaryButton!.uniqueId == elementId) {
            p.secondaryButton!.onPressed();
            break l1;
          }
        }
      } else {
        if (template is CPInformationTemplate) {
          l2:
          for (final b in template.actions) {
            if (b.uniqueId == elementId) {
              b.onPressed();
              break l2;
            }
          }
        }
      }
    }
  }

  /// Updates the [CPListTemplate]
  static void updateCPListTemplate(CPListTemplate updatedTemplate) {
    final elementId = updatedTemplate.uniqueId;
    _methodChannel
        .invokeMethod(
      FCPChannelTypes.updateListTemplate.name,
      updatedTemplate.toJson(),
    )
        .then((value) {
      if (value) {
        for (var template in templateHistory) {
          switch (template) {
            case final CPTabBarTemplate tabBarTemplate:
              for (final (tabIndex, tab) in tabBarTemplate.templates.indexed) {
                if (tab.uniqueId == elementId) {
                  tabBarTemplate.templates[tabIndex] = updatedTemplate;
                  return;
                }
              }
            case final CPListTemplate listTemplate:
              if (listTemplate.uniqueId == elementId) {
                template = updatedTemplate;
                return;
              }
            default:
          }
        }
      }
    });
  }
}
