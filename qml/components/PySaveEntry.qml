import io.thp.pyotherside 1.3

Python {
	property string base
	property var locator
	property var entry

	signal finished (bool success, var entry)

	function activate() {
		addImportPath(Qt.resolvedUrl('../../python'));
		importModule('followme', function () {
			call('followme.saveData', [base, locator, entry], function (result) {
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
