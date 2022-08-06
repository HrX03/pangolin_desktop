/*
Copyright 2021 The dahliaOS Authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'package:flutter/material.dart';
import 'package:pangolin/components/shell/shell.dart';
import 'package:pangolin/components/window/window_surface.dart';
import 'package:pangolin/components/window/window_toolbar.dart';
import 'package:pangolin/utils/data/app_list.dart';
import 'package:pangolin/utils/data/constants.dart';
import 'package:pangolin/utils/wm/wm.dart';

class WmAPI {
  late BuildContext context;
  WmAPI.of(this.context);

  late final WindowHierarchyController _windowHierarchy =
      WindowHierarchy.of(context, listen: false);

  late final ShellState _shellState = Shell.of(context, listen: false);

  static const WindowEntry windowEntry = WindowEntry(
    features: [
      ResizeWindowFeature(),
      SurfaceWindowFeature(),
      FocusableWindowFeature(),
      ToolbarWindowFeature(),
    ],
    layoutInfo: FreeformLayoutInfo(
      position: Offset(32, 32),
      size: Size(1280, 720),
    ),
    properties: {
      ResizeWindowFeature.minSize: Size(480, 360),
      SurfaceWindowFeature.elevation: 4.0,
      SurfaceWindowFeature.shape: Constants.mediumShape,
      SurfaceWindowFeature.background: PangolinWindowSurface(),
      ToolbarWindowFeature.widget: PangolinWindowToolbar(
        barColor: Colors.transparent,
        textColor: Colors.black,
      ),
      ToolbarWindowFeature.size: 40.0,
    },
  );

  void popWindowEntry(String id) {
    _windowHierarchy.removeWindowEntry(id);
  }

  void pushWindowEntry(LiveWindowEntry entry) {
    _windowHierarchy.addWindowEntry(entry);
  }

  void openApp(String packageName) {
    final application = getApp(packageName);
    if (!application.canBeOpened) {
      return;
      // throw 'The app couldn not be opened';
    }
    final LiveWindowEntry window = windowEntry.newInstance(
      content: application.app,
      overrideProperties: {
        WindowEntry.title: application.name,
        ToolbarWindowFeature.widget: PangolinWindowToolbar(
          barColor: application.color,
          textColor: application.appBarTextColor,
        ),
        WindowEntry.icon: getAppIconProvider(
          iconPath: application.iconName,
          usesRuntime: application.systemExecutable,
        ),
        WindowExtras.stableId: packageName,
      },
      overrideLayout: (info) => info.copyWith(
        size: MediaQuery.of(context).size.width < 1920
            ? const Size(720, 480)
            : MediaQuery.of(context).size.width < 1921
                ? const Size(1280, 720)
                : const Size(1920, 1080),
      ),
    );

    pushWindowEntry(window);
  }

  void minimizeAll() {
    _shellState.minimizedWindowsCache.clear();
    for (final LiveWindowEntry e in _windowHierarchy.entries) {
      if (e.layoutState.minimized) {
        _shellState.minimizedWindowsCache.add(e.registry.info.id);
      } else {
        e.layoutState.minimized = true;
      }
    }
  }

  void undoMinimizeAll() {
    for (final LiveWindowEntry e in _windowHierarchy.entries) {
      e.layoutState.minimized =
          _shellState.minimizedWindowsCache.contains(e.registry.info.id);
    }
  }
}
