# /www/bookmarks/tree-dynamic.tcl

ad_page_contract {

    Javascript tree data builder
   
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

set user_id [ad_verify_and_get_user_id]

# time
# we get this time variable only so that certain browsers (internet explorer, for instance)
# will not try to cache this page.

# get generic display parameters from the .ini file
set folder_decoration [ad_parameter FolderDecoration bm]
set hidden_decoration [ad_parameter HiddenDecoration bm]
set dead_decoration   [ad_parameter DeadDecoration   bm]

set name [db_string name_query "
select first_names||' '||last_name as name 
from   cc_users 
where  user_id = :viewed_user_id"]

set name [regsub -all {'} $name {\'}]

append js "
var TREE_ITEMS = \[
	\['Bookmarks for $name', null,
"

set root_id [bm_get_root_folder_id [ad_conn package_id] $viewed_user_id]
set prev_lev 1
set prev_folder_p "f"


db_foreach bookmark_items {} {

    append js [bm_close_js_brackets $prev_folder_p $prev_lev $lev]
    set i_str [string repeat "\t" $lev]
    set local_title [regsub -all {\\} $local_title {\\\\}]
    set local_title [regsub -all {'} $local_title {\'}]
    set complete_url [regsub -all {\\} $complete_url {\\\\}]
    set complete_url [regsub -all {'} $complete_url {\'}]


#    # decoration refers to color and font of the associated text
#    set decoration ""
#
#    # make dead links appear as definied in the .ini file
#    if {$last_checked_date != $last_live_date} {
#	append decoration $dead_decoration
#    }
#    
#    # make folder titles appear  as definied in the .ini file
#    if {$folder_p == "t"} {
#	append decoration $folder_decoration
#    }

   
    if {$folder_p == "t"} {
	append js "$i_str\['[ad_quotehtml [string trim $local_title]]', null,\n"
    } else {
	append js "$i_str\['[ad_quotehtml [string trim $local_title]]', '[string trim [ad_quotehtml $complete_url]]'],\n"
    }
    set prev_lev $lev
    set prev_folder_p $folder_p

} if_no_rows {
    append js "\t\t\['No bookmarks found'],\n\t],\n"
}

append js [bm_close_js_brackets $prev_folder_p $prev_lev 1]
append js "];\n"


doc_return  200 text/plain "$js"
