/**
 * Global variables
**/
var interval;
var loading_bar;
var tree_view;

// Some variables to hold the state of the polling.
var retries = 0;
var max_retries = 5; // Retry if test has not started
var retry_interval = 2000; // How often to poll

// Loading indicator
function load() {
	var v = document.getElementById('test');
	var s = lbl_loading + '.. ';
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
// Builds a new AJAX request for this browser
function initAjax() {
	if (window.XMLHttpRequest)
		{// code for IE7+, Firefox, Chrome, Opera, Safari
		return new XMLHttpRequest();
	}
	else {// code for IE6, IE5
		return new ActiveXObject("Microsoft.XMLHTTP");
	}
}
// This will fire off polling
function run_dnscheck() {
	interval = setInterval(pollResult, retry_interval);

	load();
	// Telling form to not submit?
	return false;
}

// Polling for result
function pollResult() {

	var xmlhttp = initAjax();
	// Callbacks
	xmlhttp.onreadystatechange=function() {
		if (xmlhttp.readyState==4 && xmlhttp.status==200) {
			var json = xmlhttp.responseText;
			try {
  				json = JSON.parse(json);
			} catch (exception) {
  				json = null;
			}
			// Valid
			var error_msg;
			if(json) {
				var json_status = json.status;
				if(json_status == 'finished') {
					// We are done. Clear loading and redirect browser
					window.location = 'tree.pl?test_id=' + json.id + '&key=' + json.key;
					clearInterval(interval);
					clearTimeout(loading_bar);
					return;
				} else if(json_status == 'error') {
					// We are not sure that our test have started
					if(json.error_key == 3 && retries < max_retries) {
						retries++;
						return;
					}
					error_msg = errors[json.error_key];
				} else {
					// Let polling continue
					return;
				}
			} else {
				error_msg = 'Malformed response returned from server.';
			}
			// Down  here we know that some error occurred
			clearInterval(interval);
			clearTimeout(loading_bar);
			document.getElementById('test').innerHTML = '<span style="color: red;">' + error_msg + '</span>';

		}
  	}
	// Set some parameters from the DOM
	var domain = document.getElementById('domain').value;
	var type = document.getElementById('type').value;

	// Pass parameters given type of test
	if(type == 'standard') {
		xmlhttp.open("GET","do-poll-result.pl?domain="+domain + "&test=" + type, true);
	} else if(type != undefined && type.match(/undelegated|moved/)) {
		var private_tld = document.getElementById('private').checked;
		xmlhttp.open("GET","do-poll-result.pl?domain="+domain +
		"&test=undelegated" + "&parameters="+source_params() +
		"&private="+private_tld, true);
	}
	xmlhttp.send();
}

// Resolve IP and set value in input field
function resolve(params) {
	// Fire of ajax call
	var xmlhttp = initAjax();
	// Callbacks
	xmlhttp.onreadystatechange=function() {
		if (xmlhttp.readyState==4 && xmlhttp.status==200) {
			var json = xmlhttp.responseText;
			try {
  				json = JSON.parse(json);
			} catch (exception) {
  				json = null;
			}
			if(json) {
				print_resolvers(json);
			}
		}
  	}
	xmlhttp.open("GET","do-host-resolve.pl?nameservers=" + params, true);
	xmlhttp.send();
}
// Returns the field values, to be queried
function source_params() {
	var el = document.getElementById("nameservers").getElementsByTagName("*");
	var params = "";
	// Check the fields
	for (var i=0; i<el.length; i++) {
		if(el[i].className == "host") {
			params += el[i].value;
		} else if(el[i].className == "IP" && el[i].value) {
			params += "/" + el[i].value + " ";
		}
	}
	return params;
}

// Returns the list of nameservers from the "HOST" field
function get_nameservers() {
	var el = document.getElementById("nameservers").getElementsByTagName("*");
	var params = "";
	// Check the fields
	for (var i=0; i<el.length; i++) {
		if(el[i].className == "host") {
			params += el[i].value + "|";
		}
	}
	return params;
}

// Writes the resolved IP addresses to DOM
function print_resolvers(json) {
	var el = document.getElementById("nameservers").getElementsByTagName("*");
	for (var i=0; i < el.length; i++) {
		if(el[i].className == "IP") {
			var tuple = json.shift();
			if(tuple != undefined && tuple.addr != undefined) {
				el[i].value = tuple.addr;
			} else {
				el[i].value = '';
			}
		}
	}
}
// Adds a new nameserver item to the initial list
function add_nameserver() {
	var ul = document.getElementById("nameservers");
	var new_li = document.createElement('li');
	new_li.innerHTML = lbl_host + ": <input type=\"text\" class=\"host\" onChange=\"return resolve(get_nameservers());\"/> " + lbl_ip + ": <input type=\"text\" class=\"IP\" /></li>";
	ul.appendChild(new_li);
}
// Displays or hides the specified element
function toggle_id(id) {
	var e = document.getElementById(id);
	if(e.style.display == 'block')
		e.style.display = 'none';
	else
		e.style.display = 'block';
}
// Function that will be triggered when selecting option in select box.
function load_locale() {
	var e = document.getElementById("locale_select");
	var params = get_params();
	// Check if we need to pass other parameters
	if(params.test_id != undefined) {
		window.location = '?test_id=' + params.test_id + '&locale=' + e.value + '&key=' + params.key;
	} else {
		window.location = '?locale=' + e.value;
	}
}
// Returns a value key par for the parameters for this location
function get_params() {
	var params = {};
	window.location.search.replace(/[?&]+([^=&]+)=([^&]*)/gi,
	function (str, key, value) {
		params[key] = value;
	});
    return params;
}
// Collapses the initial results (except for important messages)
function initialize_tree() {
	var results = document.getElementById('result_list');
	CollapsibleLists.applyTo(results, true);
	// Hide all descriptions?
	var descriptions = results.getElementsByTagName('blockquote');
	for (var i = 0, len = descriptions.length; i < len; i++ ) {
			descriptions[i].style.display = 'none';
	}
}

// Load some stuff when document finishes.
window.onload = function () {
	// Check what page we are currently displaying.
	var params = get_params();
	// Add a couple of name server fields by default
	if(params.type != undefined && params.type.match(/undelegated|moved/)) {
		add_nameserver();
		add_nameserver();
	} 
	// initialize the result tree	
	else if(tree_view) {
		initialize_tree();
	}
}
