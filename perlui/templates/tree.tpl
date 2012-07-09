[% INCLUDE header.tpl %]
<div>
 <h2>[% lng.domain_test %]</h2>
 <div id="domain_info">
  <p>Domain: [% domain %]</p>
   Test started: [% started %]<br />
   Test finished: [% finished %] <br />
   [% lng.test_was_performed_with_version %] [% version %]
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
 <div id ="domain_history">
  <h3 style="text-align: center;">[% lng.test_history %]</h3>
  <ul style="padding: 10px;">
   [% FOREACH sample IN history %]
    <li class="[% sample.2 %]">
     <a href="tree.pl?test_id=[% sample.0 %]&test=[% source %]">[% sample.1 %]</a>
    </li>
   [% END %]
  </ul>
 </div>
 <div class="clear-both"></div>
</div>
 <h3>[% lng.advanced_results %]:</h3>
 <!-- Loop all the tests -->
 <ul id="result_list">
 [% FOREACH test IN tests %]
  [% IF test.tag_start %]
   [% test.tag_start %]
  [% END %]
  <!-- Caption -->
  <div id="mod_[% test.id %]" class="[% test.class %]">
   [% custom = test.caption %]
   [% IF lng.$custom %]
    [% lng.$custom %]
   [% ELSE %]
    [% test.caption %]
   [% END %]
   [% IF test.description %]
   	<!-- Description -->
    <a href="#" onClick="toggle_id('info_[% test.id %]'); return false;">[+]</a>
    <blockquote id="info_[% test.id %]" class="description"><b>Note:</b> [% test.description %]</blockquote>
   [% END %]
  </div>
  [% test.tag_end %]
 [% END %]
 </ul>
[% INCLUDE footer.tpl %]
