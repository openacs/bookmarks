ad_page_contract {
    This page asks the user for a confirmation of whether to
    remove all individual permissions on his bookmarks. 

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
    root_folder_id:integer
    public_p
    viewed_user_id:integer

} -properties {
    page_title:onevalue
    context_bar_args:onevalue
    root_folder_id:onevalue
    viewed_user_id:onevalue
}

ad_require_permission $root_folder_id admin

set page_title "Removal of Access Permission Settings"

set context_bar_args "\[list bookmark-permissions?viewed_user_id=$viewed_user_id \"Manage Permissions on all Bookmarks\"\] \"$page_title\""


db_multirow direct_permissions direct_bookmark_permissions {select bookmark_id, local_title from bm_bookmarks
where acs_permission.permission_p(bookmark_id, acs.magic_object_id('registered_users'), 'read') <> :public_p
start with parent_id = :root_folder_id
connect by prior bookmark_id = parent_id}


ad_return_template










