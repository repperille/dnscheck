[% INCLUDE header.tpl %]
<h2>[% page_title %]</h2>
 <p>Domain: [% domain %]</p>
 <p>
  Test started: [% started %]<br />
  Test finished: [% finished %]
 </p>
 <p>
  Final result for this test:
  <div class="[% class %]">
   [% class %]
  </div>
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
    <a href="#" onclick="toggleId('info_[% test.id %]'); return false;">[ ? ]</a> <br />
    <blockquote id="info_[% test.id %]" class="description"><b>Note:</b> [% test.description %]</blockquote>
   [% END %]
  </div>
  [% test.tag_end %]
 [% END %]
[% INCLUDE footer.tpl %]
