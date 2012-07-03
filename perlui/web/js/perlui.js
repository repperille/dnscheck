/**
 * Global variables
**/
var interval;
var loading_bar;

// Loading indicator
function load() {
	var v = document.getElementById('test');
	var s = 'Laster... ';
	switch (v.innerHTML) {
	case s+'|':
		v.innerHTML = s+'/';
		break;
	case s+'/':
		v.innerHTML = s+'-';
		break;
	case s+'-':
		v.innerHTML = s+'\\';
		break;
	case s+'\\':
		v.innerHTML = s+'|';
		break;
	default:
		v.innerHTML = s+'|';
	}
	loading_bar = setTimeout(load, 200);
}

// Polling for result
function pollResult() {
	var xmlhttp;
	if (window.XMLHttpRequest)
		{// code for IE7+, Firefox, Chrome, Opera, Safari
		xmlhttp=new XMLHttpRequest();
	}
	else {// code for IE6, IE5
		xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
	}

	// Callbacks
	xmlhttp.onreadystatechange=function() {
		if (xmlhttp.readyState==4 && xmlhttp.status==200) {
			var json = xmlhttp.responseText;
			// TODO: Better parsing
			json = eval ('(' + json + ')'); 
			var json_status = json.status;
			document.getElementById('status').innerHTML = json_status;

			if(json_status == 'finished') {
				clearInterval(interval);
				clearTimeout(loading_bar);

				// Update page
				//document.getElementById('test').innerHTML = '';
				window.location = 'tree.pl?test_id=' + json.test_id;
			}
		}
  	}
	// What domain to query
	var domain = document.getElementById('domain').value;
	xmlhttp.open("GET","pollResult.pl?domain="+domain + "&test=standard", true);
	xmlhttp.send();
}

// This will fire off polling
function runAjax() {
	interval = setInterval(pollResult, 2000);

	load();
	// Telling form to not submit?
	return false;
}


function toggleId(id) {
	var e = document.getElementById(id);
	if(e.style.display == 'block')
		e.style.display = 'none';
	else
		e.style.display = 'block';
}
// Do something when document loaded?
window.onload = function () {
}
