[% INCLUDE header.tpl %]
<h2>[% page_title %]</h2>
<form>
 <input type="hidden" name="test" value="standard" />
 Domain name: <input id="domain" type="text" name="host" value="[% host %]"/> <span id="test"></span> <br />
 [% IF type == "undelegated" %]
  <ul id="nameservers">
   Host: <input type="text" class="host" onChange="return resolve(get_nameservers());"/> IP: <input type="text" class="IP"/></li>
  </ul>
  <input type="button" value="Add nameserver" onClick="add_nameserver()"/>
  <br />
 [% END %]
 <br /><input type="submit" value="Test domain" onClick="return run_dnscheck();" />
</form>
<span id="status"></span>
<span id="error_msg"></span>
 
[% INCLUDE footer.tpl %]
