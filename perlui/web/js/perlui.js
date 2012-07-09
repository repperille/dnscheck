/**
 * Global variables
**/
var interval;
var loading_bar;

// Loading indicator
function load() {
	var v = document.getElementById('test');
	var s = 'Loading... ';
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
			// TODO: Better parsing
			json = eval ('(' + json + ')'); 
			var json_status = json.status;
			if(json_status == 'finished') {
				clearInterval(interval);
				clearTimeout(loading_bar);
				window.location = 'tree.pl?test_id=' + json.test_id +
				'&test=' + json.source; 
			} else if(json_status == 'error') {
				clearInterval(interval);
				clearTimeout(loading_bar);
				var error = '<span style="color: red;">' + json.error_msg + '</span>';
				// Replace indicator with error
				document.getElementById('test').innerHTML = error;
			}
		}
  	}
	// What domain to check
	var domain = document.getElementById('domain').value;
	xmlhttp.open("GET","do-poll-result.pl?domain="+domain + "&test=standard", true);
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
			// TODO: Better parsing
			json = eval ('(' + json + ')'); 
			print_resolvers(json);
		}
  	}
	xmlhttp.open("GET","do-host-resolve.pl?nameservers=" + params, true);
	xmlhttp.send();
}
// Returns the field values, to be queried
function get_params() {
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
	new_li.innerHTML = "Host: <input type=\"text\" class=\"host\" onChange=\"return resolve(get_nameservers());\"/> IP: <input type=\"text\" class=\"IP\"/></li>";
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

function get_params() {
	var params = {};
	window.location.search.replace(/[?&]+([^=&]+)=([^&]*)/gi,
	function (str, key, value) {
		params[key] = value;
	});
    return params;
}
// Do something when document loaded?
window.onload = function () {
	CollapsibleLists.applyTo(document.getElementById('result_list'));
}
