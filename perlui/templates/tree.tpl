[% INCLUDE header.tpl %]
<script type="text/javascript">
 var tree_view = true;
 var extended_info = "[% lng.extended_info %]";
</script>
<div>
 <div id="domain_info">
 <h2>[% lng.summary_header %]</h2>
  <p>[% lng.domain_name %]: [% domain %]</p>
   [% lng.started_label %]: [% stats.started %]<br />
   [% lng.finished_label %]: [% stats.finished %] <br />
   [% lng.test_was_performed_with_version %] [% version %]
  <p>
   [% lng.error_label %]: [% stats.critical + stats.error %]<br />
   [% lng.warning_label %]: [% stats.warning %] <br />
  </p>
  <div class="[% class %]">
   <h2>
   [% IF class == 'error' || class == 'critical' %]
    [% lng.error_header %]
   [% ELSIF class == 'warning' %]
    [% lng.warning_header %]
   [% ELSE %]
    [% lng.all_tests_ok %]
   [% END %]
   </h2>
  </div>
 </div>
 <div id="domain_history">
  [% IF history.size > 0 %]
   <h3>[% lng.test_history %]</h3>
   <ul>
    [% FOREACH sample IN history %]
     <li class="[% sample.class %]">
      <a href="tree.pl?test_id=[% sample.id %]&amp;key=[% sample.key %]">[% sample.time %]</a>
     </li>
    [% END %]
   </ul>
  [% END %]
  <h3>[% lng.explanation %]</h3>
  <ul>
   <li class="error">[% lng.test_contains_errors %]</li>
   <li class="warning">[% lng.test_contains_warnings %]</li>
   <li class="ok">[% lng.test_was_ok %]</li>
   <li class="skipped">[% lng.test_was_not_performed %]</li>
  </ul>
 </div>
 <div class="clear-both"></div>
 <script>
  document.write('<p>' + extended_info + '</p>');
 </script>
</div>
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
  [% lng.link_to_this_test %]: 
  <a href="tree.pl?test_id=[% id %]&amp;key=[% key %]">
   http://[% server_name %]/tree.pl?test_id=[% id %]&amp;key=[% key %]
  </a>
 </div>
[% INCLUDE footer.tpl %]
