ad_page_contract {
    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id$
} {
   viewed_user_id:integer
} 

set return_url [ad_urlencode "tree-frame?viewed_user_id=$viewed_user_id"]

set page_content "
<html>
<head>
	<script>return_url = '$return_url' </script>
	<script language=\"JavaScript\" src=\"tree-static.js\"></script>
	<script language=\"JavaScript\" src=\"tree_tpl.js\"></script>
	<script language=\"JavaScript\" src=\"tree-dynamic?time=[ns_time]&viewed_user_id=$viewed_user_id\"></script>
</head>

<body bgcolor=#f3f3f3>
	<script>
	new tree (TREE_ITEMS, TREE_TPL);
	</script>
</body>

</html>
"

doc_return 200 text/html "$page_content"

