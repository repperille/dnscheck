
// Loading stuff
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
	setTimeout('load()',200);
}

// Ajax stuff going on
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
			alert(xmlhttp.responseText);
		}
  	}

	// What domain to query
	var domain = document.getElementById('domain').value;
	xmlhttp.open("GET","pollResult.pl?host="+domain + "&test=standard", false);
	xmlhttp.send();

	load();

}
// Do something when document loaded?
window.onload = function () {
}
