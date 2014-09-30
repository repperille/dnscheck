[% INCLUDE header.tpl %]
<script type="text/javascript">
  // Define some strings in javascript context
  var lbl_host = "[% lng.host %]";
  var lbl_ip = "[% lng.ip %]";
  var lbl_domain_syntax = "[% lng.domain_syntax_label %]";
  var lbl_loading = "[% lng.loading_header %]";
  var lbl_remove_host = "[% lng.remove_name_server %]";
  var lbl_ds_record = "[% lng.ds_record %]";
  var lbl_remove_ds_record = "[% lng.remove_ds_record %]";
  var lbl_ds_key_tag = "[% lng.ds_key_tag %]";
  var lbl_ds_algorithm = "[% lng.ds_algorithm %]";
  var lbl_ds_digest_type = "[% lng.ds_digest_type %]";
  var lbl_ds_digest = "[% lng.ds_digest %]";
  // Array containing the possible error states returned by ajax calls
  var errors = new Array(
  	"[% lng.domain_doesnt_exist_header %]",
	"[% lng.error_source_label %]",
	"[% lng.load_error_label %]",
	"[% lng.engine_error_label %]",
	"[% lng.json_error_label %]");
</script>
<form action="do-poll-result.pl">
 <input type="hidden" name="test" id="type" value="[% type %]" />
 <input type="hidden" name="js" value="0" />
 [% lng.domain_name %]: <input id="domain" type="text" name="domain" value="[% host %]"/> 
 <span id="test" style="color: green;"></span><br />
  [% IF type == "undelegated" || type == "moved" %]
   <p>
   [% IF type == "undelegated" %]
    [% lng.enter_your_undelegated_domain_name %]
   [% ELSE %]
    [% lng.moved_domain_label %]
   [% END %]
   </p>
  [% lng.name_servers %]:
  <noscript>
   <ul id="nameservers">
    <!-- Add some default slots -->
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

   <p>
    [% lng.enter_your_unpublished_ds_record %]
   </p>
  [% lng.ds_records %]:
  <noscript>
   <ul id="ds_records">
    <!-- Add some default slots -->
    <li>[% lng.ds_key_tag %]: <input type="text" class="key_tag" name="ds0"/>[% lng.ds_algorithm %]: <input type="text" class="algorithm" name="ds0"/>[% lng.ds_digest_type %]: <input type="text" class="digest_type" name="ds0"/>[% lng.ds_digest %]: <input type="text" class="digest" name="ds0"/></li>
    <li>[% lng.ds_key_tag %]: <input type="text" class="key_tag" name="ds1"/>[% lng.ds_algorithm %]: <input type="text" class="algorithm" name="ds1"/>[% lng.ds_digest_type %]: <input type="text" class="digest_type" name="ds1"/>[% lng.ds_digest %]: <input type="text" class="digest" name="ds1"/></li>
   </ul>
  </noscript>
  <script>
   document.write('<ul id="ds_records"></ul>');
  </script>
  <br />
  <script>
   document.write('<input type="button" value="[% lng.add_ds_record %]" onClick="add_ds_record()"/>');
   document.write('<br /> <br />');
  </script>

 [% ELSE %]
  <p>[% lng.enter_your_domain_name %]</p>
 [% END %]
 <!-- Action based on whether we have javascript -->
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
