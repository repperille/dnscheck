[% INCLUDE header.tpl %]
<script type="text/javascript">
  // Define some strings in javascript context
  var lbl_host = "[% lng.host %]";
  var lbl_ip = "[% lng.ip %]";
  var lbl_domain_syntax = "[% lng.domain_syntax_label %]";
</script>
<form>
 <input type="hidden" name="test" id="type" value="[% type %]" />
 [% lng.domain_name %]: <input id="domain" type="text" name="host"
value="[% host %]"/> <span id="test" style="color: green;"></span> <br />
 [% IF type == "undelegated" %]
  <p>[% lng.enter_your_undelegated_domain_name %]</p>
  [% lng.name_servers %]:
  <ul id="nameservers">
   <li>[% lng.host %]: <input type="text" class="host" onChange="return resolve(get_nameservers());"/> IP: <input type="text" class="IP"/></li>
  </ul>
  <br />
  <input type="button" value="[% lng.add_name_server %]" onClick="add_nameserver()"/>
  <br /><br />
 [% ELSE %]
  <p>[% lng.enter_your_domain_name %]</p>
 [% END %]
 <input type="submit" value="[% lng.test_now %]" onClick="return run_dnscheck();" />
</form>
[% INCLUDE footer.tpl %]
