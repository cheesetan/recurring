//
//  WidgetRefresh.swift
//  recurring
//

import WidgetKit

enum WidgetRefresh {
    static func now() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
