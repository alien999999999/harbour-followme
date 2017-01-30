import QtQuick 2.0
import io.thp.pyotherside 1.3

Python {
	property string filename: ".nomedia"

	property bool autostart

	signal finished (bool created)

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			call('followme.createDataPath', [app.dataPath, filename], function (result) {
				finished(result);
			});
		});
	}

	onError: finished(false);

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
