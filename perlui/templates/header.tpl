<!DOCTYPE html>
<html>
  <head>
    <title>[% title %]</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <script type="text/javascript" src="js/perlui.js"></script>
    <script type="text/javascript" src="js/collapseable.js"></script>
    <link rel="stylesheet" type="text/css" href="css/style.css" />
  </head>
 <body>
 <h1>Domain tester</h1>
 <ul class="menu">
  <li><a href="index.pl?type=standard">[% lng.domain_test %]</a></li>
  <li><a href="index.pl?type=undelegated">[% lng.undelegated_domain_test %]</a></li>
  <li>
   <select id="locale_select" onChange="load_locale();">
   [% FOREACH key IN locales.keys %]
    <option value="[% key %]" [% 'selected="SELECTED"' IF key == locale %]>
     [% locales.$key %]
    </option>
   [% END %]
   </select>
  </li>

 </ul>
