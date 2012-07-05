[% INCLUDE header.tpl %]
<h2>[% page_title %]</h2>
 <p>Domain: [% domain %]</p>
 <p>
  Test started: [% started %]<br />
  Test finished: [% finished %]
 </p>
 <h3>Final result for this test:</h3>
  <div class="[% class %]">
   [% IF class == 'error' %]
    [% lng.error_header %]
   [% ELSIF class == 'warning' %]
    [% lng.warning_header %]
   [% ELSE %]
    [% lng.test_was_ok %]
   [% END %]
  </div>
 <h3>[% lng.advanced_results %]:</h3>
 <!-- Loop all the tests -->
 [% FOREACH test IN tests %]
  [% IF test.tag_start %]
   [% test.tag_start %]
  [% END %]
  <!-- Caption -->
  <div id="mod_[% test.id %]" class="[% test.class %]">
   [% test.caption %]
   <!-- Description, if it exists -->
   [% IF test.description %]
    <a href="#" onClick="toggle_id('info_[% test.id %]'); return false;">[ - ]</a>
    <blockquote id="info_[% test.id %]" class="description"><b>Note:</b> [% test.description %]</blockquote>
   [% END %]
  </div>
  [% test.tag_end %]
 [% END %]
[% INCLUDE footer.tpl %]
