ad_page_contract {
    This script updates the default permissions of the 
    users root folder. If the individual permissions are to
    be reset we redirect to permissions-reset.

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
    root_folder_id:naturalnum,notnull
    viewed_user_id:naturalnum,notnull
    {private_p:boolean "f"}
    reset_all_individual_p:boolean,optional
} 

permission::require_permission -object_id $root_folder_id -privilege admin

bm_update_bookmark_private_p $root_folder_id $private_p

#  set non_default_permissions_p [db_string non_default_permissions_p "select decode(count(*), 0, 'f', 't') from bm_bookmarks
#  where acs_permission.permission_p(bookmark_id, acs.magic_object_id('registered_users'), 'read') <> :public_p
#  start with parent_id = :root_folder_id
#  connect by prior bookmark_id = parent_id"]


if { [info exists reset_all_individual_p] && $reset_all_individual_p == "t" && $non_default_permissions_p == "t" } {
    ad_returnredirect "permissions-reset-all?public_p=$public_p&viewed_user_id=$viewed_user_id&root_folder_id=$root_folder_id"
} else {
    ad_returnredirect "index?viewed_user_id=$viewed_user_id"
}







