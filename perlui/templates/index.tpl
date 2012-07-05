[% INCLUDE header.tpl %]

<form>
 <input type="hidden" name="test" value="standard" />
 [% lng.domain_name %]: <input id="domain" type="text" name="host" value="[% host %]"/> <span id="test"></span> <br />
 <p>[% lng.enter_your_domain_name %]</p>
 [% IF type == "undelegated" %]
  <p>[% lng.name_servers %]:</p>
  <ul id="nameservers">
   Host: <input type="text" class="host" onChange="return resolve(get_nameservers());"/> IP: <input type="text" class="IP"/></li>
  </ul>
  <input type="button" value="[% lng.add_name_server %]" onClick="add_nameserver()"/>
  <br /><br />
 [% END %]
 <input type="submit" value="[% lng.test_now %]" onClick="return run_dnscheck();" />
</form>
<span id="status"></span>
<span id="error_msg"></span>
 
[% INCLUDE footer.tpl %]
