import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
	id: "downloadPages"

	property string base
	property var locator

	property var outModel
	property var inModel

	property var donePagesHandler

	property int todo: inModel != undefined ? inModel.length : 0

	signal finishedPage (int index, bool success, string filename)
	signal donePages ()

	function download(items) {
		inModel = items;
		pageRepeater.model = inModel;
		for (var i in items) { pageRepeater.addItem(i, items[i]); }
	}

	function doFinishedPage(index, success, filename) {
		outModel[index] = inModel[index];
		if (success) {
			console.log("downloaded page succeeded: " + filename);
			outModel[index].absoluteFile = filename;
		}
		todo = todo - 1;
		console.log("pages left: " + todo);
		finishedPage(index, success, filename);
		if (todo == 0) {
			console.log("triggering signal donePages");
			donePages();
		}
	}

	Repeater {
		id: "pageRepeater"
		model: inModel
		delegate: Item {
			property var part: inModel[index]

			Fetch {
				locator: downloadPages.locator.concat([part.id])
				fetchautostart: part.remoteFile == undefined || part.remoteFile == '' || !part.remoteFile.match(/^[a-z0-9]+:\/\//);

				onDone: {
					console.log("downloading page: " + locator.join(',') + ": done : " + (success ? "ok" : "nok"));
					if (success) {
						console.log('parts: ' + entries.length);
						if (entries.length > 0) {
							console.log('fetch got me filename: ' + entries[0].remoteFile);
							downloadFile.url = entries[0].remoteFile;
							console.log('download dest locator: ' + downloadFile.locator.join('/'));
							downloadFile.activate();
							return ;
						}
					}
					doFinishedPage(index, false, '');
				}
				Component.onCompleted: {
					console.log("downloadpage: " + locator.join(','));
					console.log("download page file: " + part.file);
				}
			}

			PyDownloadFile {
				id: "downloadFile"
				base: downloadPages.base
				locator: downloadPages.locator.concat([part.id])

				onFinished: doFinishedPage(index, success, filename);
			}

			Component.onCompleted: {
				console.log("downloadpage: " + part.id);
			}
		}
	}

	Component.onCompleted: {
		donePages.connect(donePagesHandler);
		console.log("downloadpages: " + inModel.length + " pages");
	}
}
