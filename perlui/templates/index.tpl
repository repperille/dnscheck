[% INCLUDE header.tpl %]
<h2>DNS-sjekker</h2>
<form>
 <input type="hidden" name="test" value="standard" />
 Domenenavn: <input id="domain" type="text" name="host" value="[% host %]"/>
 <input type="submit" value="Test domene" onClick="return runAjax();" />
 <span id="test"></span> <br />
 <span id="status"></span> <br />
 <i>Versjon: [% version %]</i>
[% INCLUDE footer.tpl %]
