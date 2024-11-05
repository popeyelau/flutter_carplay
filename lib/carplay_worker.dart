import 'dart:async';
import 'package:flutter_carplay/controllers/carplay_controller.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:flutter_carplay/constants/private_constants.dart';
import 'package:flutter_carplay/models/speaker/carplay_speaker.dart';
import 'package:flutter_carplay/models/voice_control/voice_control_template.dart';

/// An object in order to integrate Apple CarPlay in navigation and
/// manage all user interface elements appearing on your screens displayed on
/// the CarPlay screen.
///
/// Using CarPlay, you can display content from your app on a customized user interface
/// that is generated and hosted by the system itself. Control over UI elements, such as
/// touch target size, font size and color, highlights, and so on.
///
/// **Useful Links:**
/// - [What is CarPlay?](https://developer.apple.com/carplay/)
/// - [Request CarPlay Framework](https://developer.apple.com/contact/carplay/)
/// - [Learn more about MFi Program](https://mfi.apple.com)
class FlutterCarplay {
  /// A main Flutter CarPlay Controller to manage the system.
  static final FlutterCarPlayController _carPlayController =
      FlutterCarPlayController();

  /// CarPlay main bridge as a listener from CarPlay and native side.
  late final StreamSubscription<dynamic>? _eventBroadcast;

  /// Current CarPlay and mobile app connection status.
  static String _connectionStatus =
      CPEnumUtils.stringFromEnum(CPConnectionStatusTypes.unknown.toString());

  /// A listener function, which will be triggered when CarPlay connection changes
  /// and will be transmitted to the main code, allowing the user to access
  /// the current connection status.
  Function(CPConnectionStatusTypes status)? _onCarplayConnectionChange;
  Function(String mediaName)? _onSiriSearch;
  Function(String action)? _onNowPlayingButtonAction;

  /// A listener function that will be triggered each time user's voice is recognized
  /// and transcripted by CarPlay voice control, allows users to access the speech
  /// recognition transcript.
  static Function(String transcript)? _onSpeechRecognitionTranscriptChange;

  /// A listener function that will be triggered when the voice control is cancelled.
  static Function()? _onCancelVoiceControl;

  /// A listener function that will be triggered when an information template is popped.
  static Function()? _onInformationTemplatePopped;

  /// Creates an [FlutterCarplay] and starts the connection.
  FlutterCarplay() {
    _eventBroadcast = _carPlayController.eventChannel
        .receiveBroadcastStream()
        .listen((event) {
      final FCPChannelTypes receivedChannelType = CPEnumUtils.enumFromString(
        FCPChannelTypes.values,
        event["type"],
      );
      switch (receivedChannelType) {
        case FCPChannelTypes.onCarplayConnectionChange:
          final CPConnectionStatusTypes connectionStatus =
              CPEnumUtils.enumFromString(
            CPConnectionStatusTypes.values,
            event["data"]["status"],
          );
          _connectionStatus =
              CPEnumUtils.stringFromEnum(connectionStatus.toString());
          if (_onCarplayConnectionChange != null) {
            _onCarplayConnectionChange!(connectionStatus);
          }
          break;
        case FCPChannelTypes.onSearchViaSiri:
          if (_onSiriSearch != null) {
            _onSiriSearch!(
              event["data"]["mediaName"],
            );
          }
          break;
        case FCPChannelTypes.onFCPListItemSelected:
          _carPlayController
              .processFCPListItemSelectedChannel(event["data"]["elementId"]);
          break;
        case FCPChannelTypes.onFCPListImageRowItemSelected:
          _carPlayController.processFCPListItemImageSelectedChannel(
            event["data"]["elementId"],
            event["data"]["index"],
          );
          break;

        case FCPChannelTypes.onFCPAlertActionPressed:
          _carPlayController
              .processFCPAlertActionPressed(event["data"]["elementId"]);
          break;
        case FCPChannelTypes.onPresentStateChanged:
          _carPlayController
              .processFCPAlertTemplateCompleted(event["data"]["completed"]);
          break;
        case FCPChannelTypes.onGridButtonPressed:
          _carPlayController
              .processFCPGridButtonPressed(event["data"]["elementId"]);
          break;
        case FCPChannelTypes.onNowPlayingButtonPressed:
          final action = event["data"]["action"];
          _onNowPlayingButtonAction?.call(action);
          break;
        case FCPChannelTypes.onBarButtonPressed:
          _carPlayController
              .processFCPBarButtonPressed(event["data"]["elementId"]);
          break;
        case FCPChannelTypes.onTextButtonPressed:
          _carPlayController
              .processFCPTextButtonPressed(event["data"]["elementId"]);
          break;
        default:
          break;
      }
    });
  }

  /// A function that will disconnect all event listeners from CarPlay. The action
  /// will be irrevocable, and a new [FlutterCarplay] controller must be created after this,
  /// otherwise CarPlay will be unusable.
  ///
  /// [!] It is not recommended to use this function if you do not know what you are doing.
  void closeConnection() {
    _eventBroadcast!.cancel();
  }

  /// A function that will resume the paused all event listeners from CarPlay.
  void resumeConnection() {
    _eventBroadcast!.resume();
  }

  /// A function that will pause the all active event listeners from CarPlay.
  void pauseConnection() {
    _eventBroadcast!.pause();
  }

  /// Callback function will be fired when CarPlay connection status is changed.
  /// For example, when CarPlay is connected to the device, in the background state,
  /// or completely disconnected.
  ///
  /// See also: [CPConnectionStatusTypes]
  void addListenerOnConnectionChange(
    Function(CPConnectionStatusTypes status) onCarplayConnectionChange,
  ) {
    _onCarplayConnectionChange = onCarplayConnectionChange;
  }

  void addListenerOnSiriSearch(
    Function(String mediaName) onSiriSearch,
  ) {
    _onSiriSearch = onSiriSearch;
  }

  void removeListenerOnSiriSearch() {
    _onSiriSearch = null;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on CarPlay connection status changed.
  void removeListenerOnConnectionChange() {
    _onCarplayConnectionChange = null;
  }

  void addListenerOnNowPlayingButtonAction(
    Function(String action) onNowPlayingButtonAction,
  ) {
    _onNowPlayingButtonAction = onNowPlayingButtonAction;
  }

  void removeListenerOnNowPlayingButtonAction() {
    _onNowPlayingButtonAction = null;
  }

  /// Current CarPlay connection status. It will return one of [CPConnectionStatusTypes] as String.
  static String get connectionStatus {
    return _connectionStatus;
  }

  /// Sets the root template of the navigation hierarchy. If a navigation
  /// hierarchy already exists, CarPlay replaces the entire hierarchy.
  ///
  /// - rootTemplate is a template to use as the root of a new navigation hierarchy. If one exists,
  /// it will replace the current rootTemplate. **Must be one of the type:**
  /// [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate] If not, it will throw an [TypeError]
  ///
  /// - If animated is true, CarPlay animates the presentation of the template, but will be ignored
  /// this flag when there isn’t an existing navigation hierarchy to replace.
  ///
  /// [!] CarPlay cannot have more than 5 templates on one screen.
  static void setRootTemplate({
    required dynamic rootTemplate,
    bool animated = true,
  }) {
    if (rootTemplate.runtimeType == CPTabBarTemplate ||
        rootTemplate.runtimeType == CPGridTemplate ||
        rootTemplate.runtimeType == CPListTemplate ||
        rootTemplate.runtimeType == CPInformationTemplate ||
        rootTemplate.runtimeType == CPPointOfInterestTemplate) {
      _carPlayController.methodChannel
          .invokeMethod('setRootTemplate', <String, dynamic>{
        'rootTemplate': rootTemplate.toJson(),
        'animated': animated,
        'runtimeType': "F" + rootTemplate.runtimeType.toString(),
      }).then((value) {
        if (value) {
          FlutterCarPlayController.currentRootTemplate = rootTemplate;
          _carPlayController.addTemplateToHistory(rootTemplate);
        }
      });
    }
  }

  /// It will set the current root template again.
  void forceUpdateRootTemplate() {
    _carPlayController.methodChannel.invokeMethod('forceUpdateRootTemplate');
  }

  /// Getter for current root template.
  /// Return one of type [CPTabBarTemplate], [CPGridTemplate], [CPListTemplate]
  static dynamic get rootTemplate {
    return FlutterCarPlayController.currentRootTemplate;
  }

  /// It will present [CPAlertTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static void showAlert({
    required CPAlertTemplate template,
    bool animated = true,
  }) {
    _carPlayController.methodChannel.invokeMethod(
        CPEnumUtils.stringFromEnum(FCPChannelTypes.setAlert.toString()),
        <String, dynamic>{
          'rootTemplate': template.toJson(),
          'animated': animated,
          'onPresent': template.onPresent != null ? true : false,
        }).then((value) {
      if (value) {
        FlutterCarPlayController.currentPresentTemplate = template;
      }
    });
  }

  /// It will present [CPActionSheetTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static void showActionSheet({
    required CPActionSheetTemplate template,
    bool animated = true,
  }) {
    _carPlayController.methodChannel.invokeMethod(
        CPEnumUtils.stringFromEnum(FCPChannelTypes.setActionSheet.toString()),
        <String, dynamic>{
          'rootTemplate': template.toJson(),
          'animated': animated,
        }).then((value) {
      if (value) {
        FlutterCarPlayController.currentPresentTemplate = template;
      }
    });
  }

  /// Removes the top-most template from the navigation hierarchy.
  ///
  /// - If animated is true, CarPlay animates the transition between templates.
  /// - count represents how many times this function will occur.
  static Future<bool> pop({bool animated = true, int count = 1}) async {
    FlutterCarPlayController.templateHistory.removeLast();
    return await _carPlayController.reactToNativeModule(
      FCPChannelTypes.popTemplate,
      <String, dynamic>{
        "count": count,
        "animated": animated,
      },
    );
  }

  /// Removes all of the templates from the navigation hierarchy except the root template.
  /// If animated is true, CarPlay animates the presentation of the template.
  static Future<bool> popToRoot({bool animated = true}) async {
    FlutterCarPlayController.templateHistory = [
      FlutterCarPlayController.currentRootTemplate
    ];
    return await _carPlayController.reactToNativeModule(
      FCPChannelTypes.popToRootTemplate,
      animated,
    );
  }

  /// Removes a modal template. Since [CPAlertTemplate] and [CPActionSheetTemplate] are both
  /// modals, they can be removed. If animated is true, CarPlay animates the transition between templates.
  static Future<bool> popModal({bool animated = true}) async {
    FlutterCarPlayController.currentPresentTemplate = null;
    return await _carPlayController.reactToNativeModule(
      FCPChannelTypes.closePresent,
      animated,
    );
  }

  /// Adds a template to the navigation hierarchy and displays it.
  ///
  /// - template is to add to the navigation hierarchy. **Must be one of the type:**
  /// [CPGridTemplate] or [CPListTemplate] [CPInformationTemplat] [CPPointOfInterestTemplate] If not, it will throw an [TypeError]
  ///
  /// - If animated is true, CarPlay animates the transition between templates.
  static Future<bool> push({
    required dynamic template,
    bool animated = true,
  }) async {
    if (template.runtimeType == CPGridTemplate ||
        template.runtimeType == CPListTemplate ||
        template.runtimeType == CPInformationTemplate ||
        template.runtimeType == CPPointOfInterestTemplate) {
      bool isCompleted = await _carPlayController
          .reactToNativeModule(FCPChannelTypes.pushTemplate, <String, dynamic>{
        "template": template.toJson(),
        "animated": animated,
        "runtimeType": "F" + template.runtimeType.toString(),
      });
      if (isCompleted) {
        _carPlayController.addTemplateToHistory(template);
      }
      return isCompleted;
    } else {
      throw TypeError();
    }
  }

  /// Navigate to the shared instance of the NowPlaying Template
  ///
  /// - If animated is true, CarPlay animates the transition between templates.
  static Future<bool> showSharedNowPlaying({
    bool isFavorited = false,
    bool isShuffle = false,
    bool animated = true,
  }) async {
    bool isCompleted = await _carPlayController
        .reactToNativeModule(FCPChannelTypes.showNowPlaying, <String, dynamic>{
      "animated": animated,
      "isFavorited": isFavorited,
      "isShuffle": isShuffle,
    });
    return isCompleted;
  }

  static Future<bool> updateNowPlaying({
    bool isFavorited = false,
    bool isShuffle = false,
  }) async {
    bool isCompleted = await _carPlayController.reactToNativeModule(
        FCPChannelTypes.updateNowPlaying, <String, dynamic>{
      "isFavorited": isFavorited,
      "isShuffle": isShuffle,
    });
    return isCompleted;
  }

  /// Updates the TabBar template it's children
  ///
  /// Only [CPListTemplate] items can be used to update the tabBar template it's children
  /// because [CPTabBarTemplate] only accepts a list of [CPListTemplate]
  static Future<bool> updateTabBarTemplates({
    required List<CPListTemplate> newTemplates,
  }) async {
    bool isCompleted = await _carPlayController.reactToNativeModule(
      FCPChannelTypes.updateTabBarTemplates,
      <String, dynamic>{
        "newTemplates": newTemplates.map((e) => e.toJson()).toList(),
      },
    );
    if (isCompleted) {
      (FlutterCarPlayController.currentRootTemplate as CPTabBarTemplate)
          .updateTemplates(newTemplates: newTemplates);
    }
    return isCompleted;
  }

  /// It will present [CPVoiceControlTemplate] modally.
  ///
  /// - template is to present modally.
  /// - If animated is true, CarPlay animates the presentation of the template.
  ///
  /// [!] CarPlay can only present one modal template at a time.
  static Future<void> showVoiceControl({
    required CPVoiceControlTemplate template,
    bool animated = true,
  }) async {
    final isSuccess = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.setVoiceControl.name,
      <String, dynamic>{
        'rootTemplate': template.toJson(),
        'animated': animated,
      },
    );

    if (isSuccess) FlutterCarPlayController.currentPresentTemplate = template;
  }

  /// Adds the specified [CPSpeaker] utterance to the queue of the speech synthesizer in CarPlay.
  static void speak(CPSpeaker speakerController) {
    if (speakerController.onCompleted != null) {
      FlutterCarPlayController.callbackObjects.add(speakerController);
    }
    _carPlayController.methodChannel
        .invokeMethod(
      FCPChannelTypes.speak.name,
      speakerController.toJson(),
    )
        .then((value) {
      if (value == false && speakerController.onCompleted != null) {
        FlutterCarPlayController.callbackObjects
            .removeWhere((e) => e.uniqueId == speakerController.uniqueId);
      }
    });
  }

  /// Changes the [CPVoiceControlTemplate]'s state to the one matching the specified
  /// identifier in [CPVoiceControlState].
  ///
  /// - identifier is a corresponding to one of the voiceControlStates associated with [CPVoiceControlTemplate].
  ///
  /// **[!] The [CPVoiceControlTemplate] applies a rate limit for voice control states, ignoring state changes
  /// occurring too rapidly or frequently in a short period of time.**
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<bool> activateVoiceControlState({
    required String identifier,
  }) async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.activateVoiceControlState.name,
      identifier,
    );
    return value;
  }

  /// The identifier of the [CPVoiceControlTemplate]'s current voice control state.
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<String?> getActiveVoiceControlStateIdentifier() async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.getActiveVoiceControlStateIdentifier.name,
      null,
    );
    return value as String?;
  }

  /// Starts recording for the voice recognition.
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<bool> startVoiceControl() async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.startVoiceControl.name,
      null,
    );
    return value as bool? ?? false;
  }

  /// Stops recording for the voice recognition.
  ///
  /// If this command is called before a voice control template is presented, a flutter error will occur.
  static Future<bool> stopVoiceControl() async {
    final value = await _carPlayController.methodChannel.invokeMethod(
      FCPChannelTypes.stopVoiceControl.name,
      null,
    );
    return value as bool? ?? false;
  }

  /// Callback function will be fired when CarPlay recognized and transcripted user's voice each time.
  static void addListenerOnSpeechRecognitionTranscriptChange({
    Function(String transcript)? onSpeechRecognitionTranscriptChange,
  }) {
    _onSpeechRecognitionTranscriptChange = onSpeechRecognitionTranscriptChange;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on CarPlay speech recognition transcript changes.
  static void removeListenerOnSpeechRecognitionTranscriptChange() {
    _onSpeechRecognitionTranscriptChange = null;
  }

  /// Callback function will be fired when user cancels voice control.
  static void addListenerOnCancelVoiceControl({
    Function()? onCancelVoiceControl,
  }) {
    _onCancelVoiceControl = onCancelVoiceControl;
  }

  /// Removes the callback function that has been set before in order to listen
  /// on user cancels voice control.
  static void removeListenerOnCancelVoiceControl() {
    _onCancelVoiceControl = null;
  }
}
