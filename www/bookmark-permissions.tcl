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

} -properties {
    page_title:onevalue
    context:onevalue
    old_public_p:onevalue
    viewed_user_id:onevalue
}

set root_folder_id [bm_get_root_folder_id [ad_conn package_id] [ad_conn user_id]]

set old_private_p [bm_bookmark_private_p $root_folder_id]

ad_require_permission $root_folder_id admin

set page_title "Manage Permissions on all Bookmarks"

set context [bm_context_bar_args [list $page_title] $viewed_user_id]

ad_return_template

