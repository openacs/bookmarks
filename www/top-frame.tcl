ad_page_contract {
    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id:
} {
    viewed_user_id:integer
    write_p
}

set browsing_user_id [ad_conn user_id]

set return_url [ad_urlencode "tree-frame?viewed_user_id=$viewed_user_id"]

doc_return 200 text/html "<head>
<style>
BODY {background-color: white}
A {text-decoration: none; color: #0000bb}
A:hover {text-decoration: underline}
</style>
</head>
<body>
<center><table width=100%cellpadding=0 border=0 cellspacing=0><tr><td>
<form target=target_frame action=search.tcl><table width=100% cellpadding=1 border=0 bgcolor=#f3f3f3>
[export_form_vars viewed_user_id]
<tr>
[ad_decode $write_p "t" "<td bgcolor=#cccccc align=center valign=middle><font size=-1 face=arial, helvetica><b><a target=main href=bookmark-add-import.tcl?viewed_user_id=$viewed_user_id&return_url=$return_url>Add/Import</a></td>" ""]
[ad_decode $browsing_user_id $viewed_user_id "<td bgcolor=#cccccc align=center valign=middle><font size=-1 face=arial, helvetica><b><a target=new href=bookmarks-export.tcl?viewed_user_id=$viewed_user_id>Export</a></td>" ""]
[ad_decode $write_p "t" "<td bgcolor=#cccccc align=center valign=middle><font size=-1 face=arial, helvetica><b><a target=main href=folder-add.tcl?viewed_user_id=$viewed_user_id&return_url=$return_url>New Folder</a></td>" ""]
</tr>
</table></td></tr><tr><td>
<table width=100% cellpadding=1 border=0 bgcolor=#f3f3f3>
<input type=hidden name=return_url value=$return_url>
<tr>
<td bgcolor=#cccccc align=center valign=middle><font size=-1 face=arial, helvetica><b><a target=main href=tree-frame.tcl?viewed_user_id=$viewed_user_id>Refresh</a></td>
<td bgcolor=#cccccc align=center valign=middle><font size=-1 face=arial, helvetica><b><a target=new href=index.tcl?viewed_user_id=$viewed_user_id>Main</a></td>
<td bgcolor=#cccccc colspan=2 align=center valign=middle><font size=-1 face=arial, helvetica><b>Search <input size=10 name=search_text></td>
</tr>
</form>
</table>   
</table>"














