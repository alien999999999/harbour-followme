import QtQuick 2.0
import io.thp.pyotherside 1.3

Python {
	property string base
	property var locator
	property bool files
	property bool autostart
	property int depth: 1
	property var excludes: [".FollowMe"]
	property string event: "received"
	property var eventHandler: onReceived

	signal started ()
	signal finished (bool success, var entries)

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			started();
			console.log('ListEntries: locator: ' + locator.length);
			console.log(locator);
			call('followme.listData', [base, locator, files, excludes, event, depth], function (result) {
				finished(result != null, result);
			});
		});
	}

	onError: finished(false, []);

	Component.onCompleted: {
		if (event != received) {
			setHandler(event, eventHandler);
		}
		if (autostart) {
			activate();
		}
	}
}
