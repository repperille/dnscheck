window.onload = function () {
}

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
