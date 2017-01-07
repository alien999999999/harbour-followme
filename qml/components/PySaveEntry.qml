import io.thp.pyotherside 1.3

Python {
	property string base
	property var entry

	signal finished (bool success, var entry)

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			if (entry.locator == undefined) {
				console.error('entry needs a locator');
			}
			call('followme.saveData', [base, entry], function (result) {
				finished(result != null, result);
			});
		});
	}

	function save(e) {
		entry = e;
		activate();
	}

	onError: finished(false, []);
}
