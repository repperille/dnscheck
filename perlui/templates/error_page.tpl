[% INCLUDE header.tpl %]
<h2>[% page_title %]</h2>
<p>
 [% IF description %]
  [% description  %]
 [% ELSE %]
  An error occurred.
 [% END %]
</p>
[% IF error || trace %]
 <h2>Debug output, should be disabled in prod</h2>
 <p>Error message: [% error %]</p>
 <p>Stack trace: [% trace %]</p>
[% END %]
[% INCLUDE footer.tpl %]
