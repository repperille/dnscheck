[% INCLUDE header.tpl %]
<h2>[% page_title %]</h2>
<p>
 [% IF description %]
  [% description  %]
 [% ELSE %]
  An error occurred.
 [% END %]
</p>
[% IF error %]
 <p>Error message: [% error %]</p>
[% END %]
[% IF trace %]
 <p>Stack trace: [% trace %]</p>
[% END %]
[% INCLUDE footer.tpl %]
