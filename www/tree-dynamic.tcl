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
    @cvs-id $Id:
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
where  user_id = :user_id"]

append js "
USETEXTLINKS = 1
aux0 = gFld(\"Bookmarks for $name\",\"<b>\")
"

set root_id [bm_get_root_folder_id [ad_conn package_id] $viewed_user_id]

db_foreach bookmark_items {
    select   b.bookmark_id, 
             b.url_id, 
             b.local_title, 
             last_live_date, 
             last_checked_date,
             b.parent_id, 
             complete_url, 
             b.folder_p
    from     (select /*+INDEX(bm_bookmarks bm_bookmarks_local_title_idx)*/ 
              bookmark_id, url_id, local_title, folder_p, 
              level lev, parent_id, owner_id, rownum as ord_num 
              from bm_bookmarks start with bookmark_id = :root_id 
              connect by prior bookmark_id = parent_id) b, 
             bm_urls
    where exists (select 1 from bm_bookmarks where acs_permission.permission_p(bookmark_id, :user_id, 'read') = 't'
            start with bookmark_id = b.bookmark_id connect by prior bookmark_id = parent_id)
    and      b.bookmark_id <> :root_id
    and      b.url_id = bm_urls.url_id(+)
    order by ord_num
} {

    # In the ACS3 version parent_id empty meant root - I am setting parent_id
    # to empty string here to make the old code work (pmarklun@arsdigita.com)
    if { [string equal $parent_id $root_id] } {
	set parent_id "0"
    }

    # decoration refers to color and font of the associated text
    set decoration ""

    # make dead links appear as definied in the .ini file
    if {$last_checked_date != $last_live_date} {
	append decoration $dead_decoration
    }
    
    # make folder titles appear  as definied in the .ini file
    if {$folder_p == "t"} {
	append decoration $folder_decoration
    }

    
    if {$folder_p == "t"} {
	append js "aux$bookmark_id = insFld(aux$parent_id, gFld(\"[philg_quote_double_quotes [string trim $local_title]]\", \"$decoration\", $bookmark_id))\n"
    } else {
	append js "aux$bookmark_id = insDoc(aux$parent_id, gLnk(1, \"[philg_quote_double_quotes [string trim $local_title]]\",\"[string trim [philg_quote_double_quotes $complete_url]]\",\"$decoration\", $bookmark_id))\n"
    }
}

doc_return  200 text/html "$js"
