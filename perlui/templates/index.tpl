[% INCLUDE header.tpl %]
<h2>DNS-sjekker</h2>
<form>
 <input type="hidden" name="test" value="standard" />
 Domenenavn: <input id="domain" type="text" name="host" value="[% host %]"/>
  [% IF type == "undelegated" %]
  <br />Host: <input type="text" name"ns1" /> IP: <input type="text" name="ip1" />
  [% END %]
 <br /><input type="submit" value="Test domene" onClick="return runAjax();" />
 <span id="test"></span> <br />
 <span id="status"></span> <br />
[% INCLUDE footer.tpl %]
