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
    return_url
    {viewed_user_id:integer ""}

} -properties {
    page_title:onevalue
    context:onevalue
    bookmark_id:onevalue
    user_id:onevalue
    viewed_user_id:onevalue
    return_url:onevalue
} 

# If viewed_user_id was not provided the browsing user_id provides
# a good default
if { [empty_string_p $viewed_user_id] } {
    set viewed_user_id [ad_conn user_id]
}


set page_title "Create Folder"

set context [bm_context_bar_args [list $page_title] $viewed_user_id]
set user_id [ad_conn user_id]

# get the next bookmark_id (used as primary key in bm_bookmarks)
set bookmark_id [db_nextval acs_object_id_seq]


ad_return_template




