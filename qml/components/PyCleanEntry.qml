import QtQuick 2.0
import io.thp.pyotherside 1.3

Python {
	property string base
	property var locators
	property var excludes: (['.FollowMe'])

	property bool autostart

	signal finished (bool success, int removed)

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			call('followme.cleanData', [base, locators, excludes], function (result) {
				console.log('cleaned ' + result + ' items');
				finished(true, result);
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
