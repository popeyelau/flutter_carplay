//
//  FCPEnums.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

enum FCPConnectionTypes {
  static let connected = "CONNECTED"
  static let background = "BACKGROUND"
  static let disconnected = "DISCONNECTED"
}

enum FCPChannelTypes {
  static let onCarplayConnectionChange = "onCarplayConnectionChange"
  static let setRootTemplate = "setRootTemplate"
  static let forceUpdateRootTemplate = "forceUpdateRootTemplate"
  static let updateListItem = "updateListItem"
  static let onListItemSelected = "onFCPListItemSelected"
  static let onListItemSelectedComplete = "onFCPListItemSelectedComplete"
  static let onListImageRowItemSelected = "onFCPListImageRowItemSelected"
  static let onAlertActionPressed = "onFCPAlertActionPressed"
  static let setAlert = "setAlert"
  static let onPresentStateChanged = "onPresentStateChanged"
  static let popTemplate = "popTemplate"
  static let pushTemplate = "pushTemplate"
  static let showNowPlaying = "showNowPlaying"
  static let updateNowPlaying = "updateNowPlaying"
  static let closePresent = "closePresent"
  static let onGridButtonPressed = "onGridButtonPressed"
  static let onNowPlayingButtonPressed = "onNowPlayingButtonPressed"
  static let setActionSheet = "setActionSheet"
  static let onBarButtonPressed = "onBarButtonPressed"
  static let onTextButtonPressed = "onTextButtonPressed"
  static let popToRootTemplate = "popToRootTemplate"
  static let updateTabBarTemplates = "updateTabBarTemplates"
  static let updateListTemplate = "updateListTemplate"
  static let onSiriSearch = "onSiriSearch"
}

enum FCPAlertActionTypes {
  case ACTION_SHEET
  case ALERT
}

enum FCPListTemplateTypes {
  case PART_OF_GRID_TEMPLATE
  case DEFAULT
}
