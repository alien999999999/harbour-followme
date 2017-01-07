import QtQuick 2.0
import io.thp.pyotherside 1.3

import "../scripts/download.js" as Utils

Python {
	property string base
	property var locator
	property string url
	property bool redownload

	property bool autostart

	signal finished (bool success, string filename)

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			console.log("url to download is: '" + url + "'");
			var suffix = Utils.getSuffix(url);
			console.log('suffix for file is: ' + suffix);
			console.log("base filename to be stored is: '" + locator[locator.length - 1]['id'] + "'");
			call('followme.downloadData', [base, locator, suffix, url, redownload], function (result) {
				console.log("filename should now be: " + result[0]);
				if (result[1] !== true) {
					console.error(result[1]);
				}
				finished(result[1] === true, result[0]);
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
