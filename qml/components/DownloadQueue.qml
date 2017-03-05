import QtQuick 2.0
import Sailfish.Silica 1.0

/** DownloadQueue
 * Keeps a queue of fetches or downloads
 * Process one by one sequentially
 ** Required Properties:
 ** RW Properties:
 * bool continueOnError
 * bool cleanupOnStop
 * bool activateOnAppend
 ** RO Properties:
 * list queue
 * int position
 * bool running
 ** Private Properties:
 * list interrupts
 * bool requestedDownloadStop
 ** public methods:
 * clear()
 * cleanup(callback)
 * append(item)
 * immediate(item, callback)
 * cancel(locator, callback)
 * activate()
 * stop(callback)
 ** private methods:
 * normalize(item)
 * insert(items)
 * doCleanup(handler)
 * doImmediate(item, handler)
 * doCancel(locator, handler)
 ** signals:
 * activated()
 * qChanged()
 * stopped()
 */
Item {
	property bool continueOnError: true
	property bool cleanupOnStop: true
	property bool activateOnAppend: true

	property var queue: []
	property int position: -1
	property int lastInsert: -1
	property bool running

	property var interrupts: []
	property bool requestedDownloadStop

	signal activated ()
	signal qChanged ()
	signal fetchDone (bool success, var entries)
	signal downloadDone (bool success, string filename, string absoluteFile)
	signal stopped ()
	signal itemNext ()

	Fetch {
		id: "fetcher"
	}

	PySaveEntry {
		id: "saveEntry"

		base: app.dataPath
	}

	PyDownloadFile {
		id: "downloader"

		base: app.dataPath
	}

	function getItem() {
		return (position >= 0 && position < queue.length ? queue[position] : undefined);
	}

	function currentLabel() {
		var item = getItem();
		if (item == undefined) {
			return '';
		}
		var p1 = item['locator'][1];
		p1 = ( p1 == undefined ? (item['locator'][0].label != undefined ? item['locator'][0].label : item['locator'][0].id) : (p1.label != undefined ? p1.label : p1.id) );
		var p2 = item['locator'].length > 2 ? item['locator'][2] : undefined;
		p2 = ( p2 == undefined ? '' : ' (' + qsTr('Chapter') + ' ' + (p2.label != undefined ? p2.label : p2.id) + ')');
		return p1 + p2;
	}

	function currentValue() {
		if (queue.length == 0) {
			return 1;
		}
		// loop and find all different originators
		// add them to a dict to be able to calc the progress value
		var progress = {}
		for (var i in queue) {
			var orig = []
			for (var j in queue[i].originator) {
				orig.push(queue[i].originator[j].id);
			}
			orig = orig.join(',');
			if (progress[orig] == undefined) {
				progress[orig] = {total: 0, finished: 0};
			}
			progress[orig].total++;
			if (queue[i].finished) {
				progress[orig].finished++;
			}
		}
		var v = 0;
		var t = 0;
		// loop the dict and calc the progress value
		for (var i in progress) {
			v += (progress[i].finished / progress[i].total);
			t++;
		}
		return (v / t);
	}

	/** doCleanup
	 * clear all finished in the queue
         * should only be called when the queue is in a non-busy state
         */
	function doCleanup(handler) {
		var i = queue.length;
		while (i > 0) {
			--i;
			if (queue[i]['finished']) {
				queue.splice(i, 1);
				// change position
				if (i <= position) {
					position--;
				}
			}
		}
		lastInsert = -1;
		qChanged();

		// trigger the cleanup handlers
		if (handler != undefined) {
			handler();
		}
	}

	/** doImmediate
	 * insert a certain item in the queue forcing it to be downloaded first
         * should only be called when the queue is in a non-busy state
         */
	function doImmediate(item, handler) {
		// child inserts (ie: same originator), will be truely inserted, but the others will be appended after the last insert (in reminder of the inserting)
		normalize(item);
		var insertPoint = lastInsert + 1;
		// by default, insert after the last insert, except in children
		if (lastInsert == -1 || item.originator == queue[position].originator) {
			insertPoint = position + 1;
		}
		queue.splice(insertPoint, 0, item);
		lastInsert = insertPoint;
		qChanged();

		// trigger the cleanup handlers
		if (handler != undefined) {
			handler();
		}
	}

	/** doCancel
	 * cancels downloading a certain item in the queue
         * should only be called when the queue is in a non-busy state
         */
	function doCancel(locator, handler) {
		var i = queue.length;
		while (i > 0) {
			--i;
			if (queue[i]['locator'] == locator) {
				queue.splice(i, 1);
				// change position
				if (i < position) {
					position--;
				}
			}
		}
		qChanged();

		// trigger the cleanup handlers
		if (handler != undefined) {
			handler();
		}
	}

	/** normalize
	 * fill in the optional properties with their defaults
	 **
	 * item: {entry: ..., locator: ..., finished: bool, depth: int, originator: ..., redownload: bool, doneHandler: function (bool) {return [];}}
	 */
	function normalize(item) {
		if (item['locator'] == undefined) {
			console.error("cannot normalize an item without locator!!!: " + item);
			console.trace();
			return ;
		}
		if (item['finished'] == undefined) {
			item['finished'] = false;
		}
		if (item['originator'] == undefined) {
			item['originator'] = item['locator'];
		}
		if (item['depth'] == undefined) {
			item['depth'] = 0;
		}
		if (item['redownload'] == undefined) {
			item['redownload'] = false;
		}
		if (item['sort'] != undefined && item['sort'] === true) {
			console.log('assigning default sort function');
			item['sort'] = function (a,b) {
				if (a == undefined || b == undefined) {
					return 0;
				}
				var sa = parseInt(a.id);
				var sb = parseInt(b.id);
				if (sa == NaN || sb == NaN || ('' + sa) != a.id || ('' + sb) != b.id) {
					sa = a.id;
					sb = b.id;
				}
				return ( sa < sb ? -1 : (sa > sb ? 1 : 0));
			};
		}
		if (item['doneHandler'] == undefined) {
			if (item['remoteFile'] != undefined) {
				item['doneHandler'] = function (success, item, absoluteFile, saveEntry){
					console.log('default doneHandler for downloading (' + item['pageIndex'] + ': ' + absoluteFile + '): ' + success);
					if (success && item['chapter'] != undefined && item['pageIndex'] != undefined && item['chapter'].items[item['pageIndex']] != undefined) {
						// only save if it's needed, but trigger the handler either way
						if (item['chapter'].items[item['pageIndex']]['absoluteFile'] != absoluteFile) {
							item['chapter'].items[item['pageIndex']]['absoluteFile'] = absoluteFile;
							console.log('saving chapter after download (filename: ' + absoluteFile + ')');
							saveEntry.save(item['chapter'], item['saveHandler']);
						}
						else {
							// trigger the handler even if it didn't need saving...
							if (item['saveHandler'] != undefined) {
								item['saveHandler'](success, item['chapter']);
							}
						}
					}
					item['absoluteFile'] = absoluteFile;
					if (item['signal'] != undefined) {
						item['signal'](success, item);
					}
					return [];
				};
			}
			else {
				item['doneHandler'] = function (success, item, entries, saveEntry){
					console.log('default doneHandler for fetching');
					var res = [];
					if (success) {
						if (item['entry'] != undefined) {

							// set locator if there isn't any (for saving purposes)
							if (item['entry'].locator == undefined && item['locator'] != undefined) {
								item['entry'].locator = item['locator'];
							}

							var changedData = false;

							// don't forget to set the actual entries
							if (app.isLevelType(item['locator'], "part")) {
								console.log('need to assign remoteFile only (in the entries)');
								// find the old part first (in the entry's items)
								for (var i in item['entry'].items) {
									if (item['entry'].items[i].id == item['locator'][item['locator'].length - 1].id) {
										console.log('assigned remoteFile to item: ' + item['entry'].items[i].id);
										if (item['entry'].items[i].remoteFile != entries[0].remoteFile) {
											changedData = true;
											item['entry'].items[i].remoteFile = entries[0].remoteFile;
										}
										if (entries[0].absoluteFile != undefined && item['entry'].items[i].absoluteFile != entries[0].absoluteFile) {
											changedData = true;
											item['entry'].items[i].absoluteFile = entries[0].absoluteFile;
										}
									}
								}
							}
							else {
								if (item['entry'].items == undefined || item['entry'].items.length != entries.length) {
									changedData = true;
									item['entry'].items = entries;
								}
							}
							console.log('saving entry after fetch (items: ' + entries.length + ')');

							if (changedData) {
								// save the entry
								saveEntry.save(item['entry'], item['saveHandler']);
							}
							else {
								// trigger the handler even if it didn't need saving...
								if (item['saveHandler'] != undefined) {
									item['saveHandler'](success, item['entry']);
								}
							}
						}

						// if depth wasn't 1, then this is not the end...
						if (item['depth'] != 1) {
							for (var i in entries) {
								var req = {
									locator: item.locator.concat([{id: entries[i].id, file: entries[i].file, label: entries[i].label}]),
									originator: item.originator,
									depth: item['depth'] == 0 ? 0 : item['depth'] - 1
								};
								console.log('add child request: locator length: ' + req.locator.length);

								if (item['saveHandler'] != undefined) {
									req['saveHandler'] = item['saveHandler'];
								}

								// transfer sort function to the child requests!
								if (item['sort'] != undefined) {
									req['sort'] = item['sort'];
								}

								// act differently for child requests depending on what level we're at
								if (app.isDownload(req.locator)) {
									console.log('add download child request: "' + entries[i].remoteFile + '"');
									if (entries[i].remoteFile != undefined) {
										req['remoteFile'] = entries[i].remoteFile;
										// if pageindex and entry are set, make sure to pass on the chapter and pageIndex
										if (item['pageIndex'] != undefined && item['entry'] != undefined) {
											req['chapter'] = item['entry'];
											req['pageIndex'] = item['pageIndex'];
										}
									}
									else {
										console.error('no remoteFile found, so, no child request...');
										continue;
									}
								}
								else {
									if (app.isLevelType(req.locator, "part")) {
										console.log('add fetch child request for a part (no subdirs for this one!), page: ' + i);
										req['entry'] = item['entry'];
										req['pageIndex'] = i;
									}
									else {
										console.log('add fetch child request');
										req['entry'] = entries[i];
									}
								}
								res.push(req);
							}
						}
					}
					if (item['signal'] != undefined) {
						item['signal'](success, item);
					}
					return res;
				};
			}
		}
		return item;
	}

	/** insert
	 * insert items inside the queue at the current position
	 * should only be executed at end of a download
	 **
	 * items: [{locator: ..., depth: int}, ...]
	 */
	function insert(items) {
		// TODO: make sure this only happens between next items
		for (var i in items) {
			queue.splice(position + parseInt(i) + 1, 0, normalize(items[i]));
		}
		qChanged();
	}

	/** nextPosition
	 * get the next available position
	 */
	function nextPosition() {
		// if queue is empty exit early
		if ((position + 1) >= queue.length) {
			return false;
		}
		var item;

		// get next item in queue
		do {
			position++;
			if (queue[position] != undefined && !queue[position]['finished']) {
				item = queue[position];
			}
		} while (position < queue.length && item == undefined);
		qChanged();

		// if no suitable item is found, return false
		if (item == undefined) {
			return false;
		}

		return true;
	}

	/** downloadNext()
	 * start downloading the next item in the queue
	 */
	function downloadNext() {
		// get the next position
		if (!nextPosition()) {
			console.warn('stop due to no next position!');
			lastInsert = -1;
			stopped();
			running = false;
			return ;
		}
		running = true;

		var item = queue[position];

		// depending on the type, start fetching it
		if (item['locator'] == undefined) {
			console.error("locator at queue[" + position + "] needs to be defined");
			// TODO: check for continue on error
			lastInsert = -1;
			stopped();
			running = false;
			return ;
		}
		console.log("next locator has length: " + item['locator'].length);

		// download instead of fetch
		console.log("remoteFile?: " + item['remoteFile']);
		if (item['remoteFile'] != undefined) {
			console.log("downloading a file: " + item['remoteFile']);
			// downloaders needs the page locator (not the actual image), iow: the parent
			downloader.locator = item['locator'].slice(0, item['locator'].length - 1);
			downloader.url = item['remoteFile'];
			downloader.redownload = item['redownload'];
			downloader.activate();
			return ;
		}

		// fetch entry
		console.log("fetching an item: " + item['entry']);
		fetcher.locator = item['locator'];
		fetcher.searchName = '';
		// this takes care of search requests
		if (item['searchName'] != undefined) {
			fetcher.searchName = item['searchName'];
		}
		// this takes care of needing provider in the entry results
		if (item['needProvider'] != undefined) {
			fetcher.needProvider = item['needProvider'];
		}
		fetcher.activate();
	}

	/** handleInterrupts
	 * handle interrupt requests
	 */
	function handleInterrupts() {
		while (interrupts.length > 0) {
			var inter = interrupts.shift();
			console.log('handle interrupt type ' + inter.type);
			if (inter.type == 'cleanup') {
				doCleanup(inter.handler);
			}
			if (inter.type == 'immediate') {
				doImmediate(inter.item, inter.handler);
			}
			if (inter.type == 'cancel') {
				doCancel(inter.locator, inter.handler);
			}
			if (inter.type == 'stop') {
				requestedDownloadStop = true;
				inter.handler();
			}
		}
	}

	/** handleNextOrEnd
	 * check if there's a next to be done or not
	 */
	function handleNextOrEnd(success) {
		// last chance for handling interrupts
		handleInterrupts();
		// check if nothing left
		console.log('ok, so, position is ' + position + ' but queue length is ' + queue.length);
		if ((position + 1) >= queue.length || requestedDownloadStop) {
			lastInsert = -1;
			stopped();
			running = false;
			if (cleanupOnStop && (position + 1) >= queue.length) {
				doCleanup(undefined);
			}
		}
		else {
			console.log('lets do the next one if ' + success);
			if (success || continueOnError) {
				itemNext();
			}
		}
	}

	/** clear
	 * clear all in queue
         * only works when not running
         */
	function clear() {
		if (!running) {
			queue = [];
			position = 0;
			qChanged();
		}
	}

	/** cleanup
	 * clear all finished in the queue
         * needs to wait until the queue is in a non-busy state --> signal it
         */
	function cleanup(callback) {
		if (!running) {
			doCleanup(callback);
		}
		else {
			interrupts.push({type: 'cleanup', handler: callback});
		}
	}

	/** append
	 * append an item in the queue
	 **
	 * item: {locator: ..., finished: bool, depth: int, originator: ..., redownload: bool, doneHandler: function (success, item){return [];}}
	 */
	function append(item) {
		console.log(item);
		for (var i in item) {
			console.log(" - " + i + ": " + item[i]);
		}
		if (item['locator'] == undefined) {
			console.log("append: locator is undefined");
		}
		queue.push(normalize(item));
		qChanged();

		// activate the queue
		if (!running && activateOnAppend) {
			activate();
		}
	}

	/** immediate
	 * do this immediate asap
         * needs to wait until the queue is in a non-busy state --> signal it
         */
	function immediate(item, callback) {
		if (!running) {
			doImmediate(item, callback);
			console.log('activate immediately...');
			activate();
		}
		else {
			interrupts.push({type: 'immediate', item: item, handler: callback});
		}
	}

	/** cancel
	 * cancel for a certain locator
         * needs to wait until the queue is in a non-busy state --> signal it
         */
	function cancel(locator, callback) {
		// TODO: cancel from immediate?
		if (!running) {
			doCancel(locator, callback);
		}
		else {
			interrupts.push({type: 'cancel', locator: locator, handler: callback});
		}
	}

	/** activate
	 * activate the downloading
	 */
	function activate() {
		requestedDownloadStop = false;
		activated();
		if (!running) {
			downloadNext();
		}
	}

	/** stop
	 * stop the downloading
         * needs to wait until the queue is in a non-busy state --> signal it
	 */
	function stop(callback) {
		if (!running) {
			callback();
		}
		else {
			interrupts.push({type: 'stop', handler: callback});
		}
	}

	onItemNext: {
		downloadNext();
	}

	onFetchDone: {
		var item = queue[position];
		item['finished'] = true;
		console.log('fetchDone of ' + item + ' at queue position ' + position);

		// first handle the interrupts
		handleInterrupts();

		// check if sorting is required
		if (item['sort'] != undefined && entries.length > 1) {
			console.log('sorting the items properly');
			console.log('before sort: ' + entries[1].id);
			entries.sort(item['sort']);
			console.log('after sort: ' + entries[1].id);
		}

		// signal the done Handler for the item
		console.log('trigger doneHandler of the item');
		var results = item['doneHandler'](success, item, entries, saveEntry);

		// check if needs to expand fetching when done
		if (results != undefined && results.length > 0) {
			console.log('inserting results from the doneHandler');
			insert(results);
		}

		// check if nothing left
		handleNextOrEnd(success);
	}

	onDownloadDone: {
		var item = queue[position];
		item['finished'] = true;
		item['filename'] = filename;
		console.log('downloadDone of ' + item + ' at queue position ' + position + '; filename: ' + filename);

		// first handle the interrupts
		handleInterrupts();

		// signal the done Handler for the item
		console.log('trigger doneHandler of the item');
		var results = item['doneHandler'](success, item, absoluteFile, saveEntry);

		// no expanding required

		// check if nothing left
		handleNextOrEnd(success);
	}

	Component.onCompleted: {
		fetcher.done.connect(fetchDone);
		downloader.finished.connect(downloadDone);
	}
}
