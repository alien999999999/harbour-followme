import QtQuick 2.0
import io.thp.pyotherside 1.3

Python {
	property string base
	property var locator
	property string url
	property bool redownload

	property bool autostart

	signal finished (bool success, string filename)

	function getSuffix(remoteFile) {
		var l = remoteFile.split('/');
		var suffix = '';
		var r = l[l.length - 1].match(/\.[a-z0-9]{3,4}$/);
		if (r != null) {
			suffix = r[0];
		}
		return suffix;
	}

	function getAbsoluteFile(remoteFile) {
		var l = locator.slice();
		var item = l.pop();
		var suffix = getSuffix(remoteFile);
		var file = item['id'].replace('/','-') + suffix;
		var folder = base.replace('~', '/home/nemo');
		for (var i in l) {
			folder += '/' + l[i]['id'].replace('/','-');
		}
		return folder + '/' + file;
	}

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			console.log("url to download is: '" + url + "'");
			var l = url.split('/');
			console.log("filename is: " + l[l.length - 1]);
			var suffix = '';
			var r = l[l.length - 1].match(/\.[a-z0-9]{3,4}$/);
			if (r != null) {
				suffix = r[0];
			}
			console.log('suffix for file is: ' + suffix);
			console.log("base filename to be stored is: '" + locator[locator.length - 1]['id'] + "'");
			call('followme.downloadData', [base, locator, suffix, url, redownload], function (result) {
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
