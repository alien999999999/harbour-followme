import QtQuick 2.0
import io.thp.pyotherside 1.3

Python {
	property string path

	property bool autostart

	signal finished (string dataPath)

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			call('followme.dataPath', [path], function (result) {
				finished(result);
			});
		});
	}

	onError: finished('');

	Component.onCompleted: {
		if (autostart) {
			activate();
		}
	}
}
