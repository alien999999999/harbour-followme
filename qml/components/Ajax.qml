import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
	property string url
	property bool autostart

	property var xhr: new XMLHttpRequest

	signal started ()
	signal finished (string data)

	function activate() {
		started();
		console.log("Ajax.activate(): getting url '" + url + "'...");
		xhr.open("GET", url);
		xhr.onreadystatechange = function() {
			if (xhr.readyState == XMLHttpRequest.DONE) {
				finished(xhr.responseText);
			}
		}
		xhr.send();
	}

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
