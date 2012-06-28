[% INCLUDE header.tpl %]
<form action="index.pl">
 <input type="hidden" name="test" value="standard" />
 Domenenavn: <input type="text" name="host" value="[% host %]"/> <br />
 <input type="submit" value="Test" /> <br />
 Versjon: [% version.0 %] <br />
 status: [% status %] <br />
 running id [% id %]
[% INCLUDE footer.tpl %]
