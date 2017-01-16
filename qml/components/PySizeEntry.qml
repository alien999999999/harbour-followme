import QtQuick 2.0
import io.thp.pyotherside 1.3

Python {
	property string base
	property var locator

	property bool autostart

	signal finished (bool success, int size)

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			console.log("get size of '" + locator[locator.length - 1]['id'] + "'");
			call('followme.dataSize', [base, locator], function (result) {
				console.log('size is ' + result);
				finished(result > 0, result);
			});
		});
	}

	onError: finished(false, 0);

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
