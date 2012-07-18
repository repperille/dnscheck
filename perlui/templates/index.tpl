[% INCLUDE header.tpl %]
<script type="text/javascript">
  // Define some strings in javascript context
  var lbl_host = "[% lng.host %]";
  var lbl_ip = "[% lng.ip %]";
  var lbl_domain_syntax = "[% lng.domain_syntax_label %]";
  var lbl_loading = "[% lng.loading_header %]";
  // Array containing the possible error states returned by ajax calls
  var errors = new Array(
  	"[% lng.domain_doesnt_exist_header %]",
	"[% lng.error_source_label %]",
	"[% lng.load_error_label %]");
</script>
<form action="do-noscript-lookup.pl">
 <input type="hidden" name="test" id="type" value="[% type %]" />
 [% lng.domain_name %]: <input id="domain" type="text" name="domain" value="[% host %]"/> <span id="test" style="color: green;"></span><br />
 [% IF type == "undelegated" %]
  <p>[% lng.enter_your_undelegated_domain_name %]</p>
  [% lng.name_servers %]:
  <noscript>
   <ul id="nameservers">
    <!-- Add some slots -->
    <li>[% lng.host %]: <input type="text" class="host" name="host0"/> IP: <input type="text" class="IP" name="ip0"/></li>
    <li>[% lng.host %]: <input type="text" class="host" name="host1"/> IP: <input type="text" class="IP" name="ip1"/></li>
   </ul>
  </noscript>
  <script>
   document.write('<ul id="nameservers"></ul>');
  </script>
  <br />
  <script>
   document.write('<input type="button" value="[% lng.add_name_server %]" onClick="add_nameserver()"/>');
   document.write('<br /> <br />');
  </script>
 [% ELSE %]
  <p>[% lng.enter_your_domain_name %]</p>
 [% END %]
 <!-- Action based on whether we got javascript -->
 <script>
  document.write('<input type="submit" value="[% lng.test_now %]" onClick="return run_dnscheck();" />');
 </script>
 <noscript>
  <input type="submit" value="[% lng.test_now %]" /><br /><br />
  <fieldset class="noscript">
   <legend>[% lng.no_script_header%]</legend>
    [% lng.no_script_label %]
  </fieldset>
 </noscript>
</form>
[% INCLUDE footer.tpl %]
