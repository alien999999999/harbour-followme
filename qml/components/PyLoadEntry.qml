import QtQuick 2.0
import io.thp.pyotherside 1.3

Python {
	property string base
	property var locator
	property bool autostart

	signal finished (bool success, var entry)

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			call('followme.loadData', [base, locator], function (result) {
				finished(result != false && result.error == undefined, result);
			});
		});
	}

	onError: finished(false, null);

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
