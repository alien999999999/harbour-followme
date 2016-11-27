import QtQuick 2.0
import io.thp.pyotherside 1.3

Python {
	property string base
	property var locator
	property string url
	property bool autostart

	signal finished (bool success, string filename)

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			var l = url.split('/');
			console.log("filename is: " + l[l.length - 1]);
			var suffix = '';
			var r = l[l.length - 1].match(/\.[a-z0-9]{3,4}$/);
			if (r != null) {
				suffix = r[0];
			}
			console.log('suffix for file is: ' + suffix);
			call('followme.downloadData', [base, locator, suffix, url], function (result) {
				finished(result != false, result);
			});
		});
	}

	onError: finished(false, '');

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
