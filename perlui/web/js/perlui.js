/**
 * Global variables
**/
var interval;
var loading_bar;
var tree_view;

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
	interval = setInterval(pollResult, 2000);

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
					window.location = 'tree.pl?test_id=' + json.test_id;
				} else if(json_status == 'error') {
					error_msg = json.error_msg;
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
	// What domain to check
	var domain = document.getElementById('domain').value;
	var type = document.getElementById('type').value;

	// Pass parameters given type of test
	if(type == 'standard') {
		xmlhttp.open("GET","do-poll-result.pl?domain="+domain + "&test=" + type, true);
	} else {
		xmlhttp.open("GET","do-poll-result.pl?domain="+domain + "&test=" + type
		+"&parameters="+source_params(), true);
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
	for (var i=0; i<el.length; i++) {
		if(el[i].className == "IP") {
			var address = json.shift().addr;
			if(address != undefined) {
				el[i].value = address;
			}
		}
	}
}
// Adds a new nameserver item to the initial list
function add_nameserver() {
	var ul = document.getElementById("nameservers");
	var new_li = document.createElement('li');
	new_li.innerHTML = lbl_host + ": <input type=\"text\" class=\"host\" onChange=\"return resolve(get_nameservers());\"/> IP: <input type=\"text\" class=\"" + lbl_ip + "\"/></li>";
	ul.appendChild(new_li);
}
// Displayes or hides the specified element
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
		window.location = '?test_id=' + params.test_id + '&locale=' + e.value;
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
// Triggered by viewing the 'advanced results'
function show_results() {
	var results = document.getElementById('result_list');
	CollapsibleLists.applyTo(results, true);
	var children = results.getElementsByTagName('li');
	for (var i = 0, len = children.length; i < len; i++ ) {
		var child_class = children[i].className;
		if(child_class == 'info' || child_class == 'notice') {
			children[i].style.display= 'block';
		}
	}
	// Hack to actual display the lists
	CollapsibleLists.applyTo(results, true);
	// Update buttons
	toggle_buttons(false);
}
// Triggered by viewing the 'basic results'
function hide_results() {
	var results = document.getElementById('result_list');
	var children = results.getElementsByTagName('li');
	for (var i = 0, len = children.length; i < len; i++ ) {
		var child_class = children[i].className;
		if(child_class == 'info' || child_class == 'notice') {
			children[i].style.display = 'none';
		}
	}
	// Hide all descriptions?
	var descriptions = results.getElementsByTagName('blockquote');
	for (var i = 0, len = descriptions.length; i < len; i++ ) {
			descriptions[i].style.display = 'none';
	}

	toggle_buttons(true);
}
// Toggles enable state of the buttons
function toggle_buttons(basic) {
	document.getElementById('btn_basic').disabled = basic;
	document.getElementById('btn_advanced').disabled = !basic;
}

// Load some stuff when document finishes.
window.onload = function () {
	// Check what page we are currently displaying.
	var params = get_params();
	if(params.type == 'undelegated') {
		add_nameserver();
	} else if(tree_view) {
		hide_results();
	}
}
