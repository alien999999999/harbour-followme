import QtQuick 2.0
import Sailfish.Silica 1.0

import "../scripts/download.js" as Utils

Item {
	property string url
	property bool autostart

	signal started ()
	signal finished (var status, string data)

	function activate() {
		started();
		Utils.ajax(url, function (status, data) {
			finished(status, data);
		});
	}

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
