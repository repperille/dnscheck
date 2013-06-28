[% TRY %]
  [% INCLUDE header_local.tpl %]
[% CATCH %]
<!DOCTYPE html>
<html>
  <head>
    <title>[% title %]</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <script type="text/javascript" src="js/perlui.js"></script>
    <script type="text/javascript" src="js/collapseable.js"></script>
    <script type="text/javascript" src="js/json2.js"></script>
    <link rel="stylesheet" type="text/css" href="css/style.css" />
  </head>
 <body>
 <h1>Domain tester</h1>
 <ul class="menu">
  <li><a href="index.pl?type=standard">[% lng.domain_test %]</a></li>
  <li><a href="index.pl?type=undelegated">[% lng.undelegated_domain_test %]</a></li>
  <li><a href="index.pl?type=moved">[% lng.moved_domain_test %]</a></li>
  <li><a href="about.pl">[% lng.about_label %]</a></li>
  <li style="float: right;">
   <form>
    [% lng.language %]:
    <select name="locale" id="locale_select" onChange="load_locale();">
     [% FOREACH locale_key IN locales.keys %]
      <option value="[% locale_key %]" [% 'selected="SELECTED"' IF locale_key == locale %]>
       [% locales.$locale_key %]
      </option>
     [% END %]
    </select>
    <noscript>
     [% IF id && key %]
      <!-- Carry through to get back to the test result -->
      <input type="hidden" name="test_id" value="[% id %]" />
      <input type="hidden" name="key" value="[% key %]" />
     [% END %]
     <input type="submit" value="[% lng.btn_save %]">
    </noscript>
   </form>
  </li>
 </ul>
 [% IF last.test_id && last.key && !key %]
  <div id="last_result">
   <a href="tree.pl?test_id=[% last.test_id %]&amp;key=[% last.key%]">
    [% lng.last_result_header %]
   </a>
  </div>
 [% END %]
[% END %]
