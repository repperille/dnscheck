[% INCLUDE header.tpl %]
<script type="text/javascript">
  // Define some strings in javascript context
  var lbl_host = "[% lng.host %]";
  var lbl_ip = "[% lng.ip %]";
  var lbl_domain_syntax = "[% lng.domain_syntax_label %]";
  var lbl_loading = "[% lng.loading_header %]";
</script>
<form action="do-noscript-lookup.pl">
 <input type="hidden" name="test" id="type" value="[% type %]" />
 [% lng.domain_name %]: <input id="domain" type="text" name="domain" value="[% host %]"/> <span id="test" style="color: green;"></span><br />
 [% IF type == "undelegated" %]
  <p>[% lng.enter_your_undelegated_domain_name %]</p>
  [% lng.name_servers %]:
  <ul id="nameservers">
   <noscript>
    <!-- Add some slots -->
    <li>[% lng.host %]: <input type="text" class="host" name="host0"/> IP: <input type="text" class="IP" name="ip0"/></li>
    <li>[% lng.host %]: <input type="text" class="host" name="host1"/> IP: <input type="text" class="IP" name="ip1"/></li>
   </noscript>
  </ul>
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
   <legend>Notice</legend>
   You are running without javascript. Please remain calm while the test
   carries out, and you will be redirected to the results in a little while.
  </fieldset>
 </noscript>
</form>
[% INCLUDE footer.tpl %]
