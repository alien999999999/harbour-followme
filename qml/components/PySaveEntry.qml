import io.thp.pyotherside 1.3

Python {
	property string base
	property var entry
	property var handlers: []

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

	function finishAndDisconnect(s, e) {
		for (var i in handlers) {
			handlers[i](s, e);
		}
		handlers = [];
	}

	function addHandler(h) {
		handlers.push(h);
	}

	function save(e, h) {
		entry = e;
		if (h != undefined) {
			addHandler(h);
		}
		finished.connect(finishAndDisconnect);
		activate();
	}

	onError: finished(false, []);
}
