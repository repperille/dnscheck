[% INCLUDE header.tpl %]
<script type="text/javascript">
 var tree_view = true;
</script>
<div>
 <div id="domain_info">
 <h2>Summary</h2>
  <p>Domain: [% domain %]</p>
   Test started: [% stats.started %]<br />
   Test finished: [% stats.finished %] <br />
   [% lng.test_was_performed_with_version %] [% version %]
  <p>
   Error(s): [% stats.critical + stats.error %]<br />
   Warning(s): [% stats.warning %] <br />
  </p>
  <div class="[% class %]">
   <h3>
   [% IF class == 'error' %]
    [% lng.error_header %]
   [% ELSIF class == 'warning' %]
    [% lng.warning_header %]
   [% ELSE %]
    [% lng.all_tests_ok %]
   [% END %]
   </h3>
  </div>
 </div>
 <div id="domain_history">
  <h3>[% lng.test_history %]</h3>
  <ul>
   [% FOREACH sample IN history %]
    <li class="[% sample.class %]">
     <a href="tree.pl?test_id=[% sample.id %]&key=[% sample.key %]">[% sample.time %]</a>
    </li>
   [% END %]
  </ul>
  <h3>[% lng.explanation %]</h3>
  <ul>
   <li class="error">[% lng.test_contains_errors %]</li>
   <li class="warning">[% lng.test_contains_warnings %]</li>
   <li class="ok">[% lng.test_was_ok %]</li>
   <li class="skipped">[% lng.test_was_not_performed %]</li>
  </ul>
 </div>
 <div class="clear-both"></div>
</div>
 <script>
  document.write('<input type="button" disabled="true" onClick="hide_results();" id="btn_basic" value="[% lng.basic_results %]">');
  document.write('<input type="button" onClick="show_results();" id="btn_advanced" value="[% lng.advanced_results %]">');
 </script>
 <!-- Loop all the tests -->
 <ul id="result_list">
 [% FOREACH test IN tests %]
  [% IF test.tag_start %]
   [% test.tag_start %]
  [% ELSE %]
   <li class="[% test.class %]">
  [% END %]
  <!-- Caption -->
  [% custom = test.caption %]
  [% IF lng.$custom %]
   [% lng.$custom %]
  [% ELSE %]
   [% test.caption %]
  [% END %]
  [% IF test.description %]
   <!-- Description -->
   <a href="#" onClick="toggle_id('info_[% test.id %]'); return false;">
   <script>
    document.write('[+]');
   </script>
   </a>
   <blockquote id="info_[% test.id %]" class="description">
    <noscript> 
	 [% lng.note %]: 
	</noscript>
	[% test.description %]
   </blockquote>
  [% END %]
  [% test.tag_end %]
 [% END %]
 </ul>
 <div style="text-align: center; font-size: 12px;">
  [% lng.link_to_this_test %]: <a href="tree.pl?test_id=[% id %]&key=[% key %]">
  http://[% server_name %]/tree.pl?test_id=[% id %]&key=[% key %]</a>
 </div>
[% INCLUDE footer.tpl %]
