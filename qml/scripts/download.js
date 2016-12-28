.pragma library

function ajax(url, callback) {
	var xhr = new XMLHttpRequest;
	xhr.open("GET", url);
	xhr.onreadystatechange = function() {
		console.log('xhr state change: ' + xhr.readyState);
		console.trace();
		if (xhr.readyState == XMLHttpRequest.DONE) {
			console.log('xhr statusText: ' + xhr.statusText);
			console.log('xhr status: ' + xhr.status);
			if (callback != undefined) {
				callback(xhr.status, xhr.responseText);
			}
		}
	}
	return xhr.send();
}
