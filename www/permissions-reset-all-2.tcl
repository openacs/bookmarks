ad_page_contract {
    This script removes all individual bookmark access 
    permission settings for the user.
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
    viewed_user_id:integer
} 

ad_require_permission $root_folder_id admin

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]


db_dml delete_individual_permissions "delete from acs_permissions where object_id in (select bookmark_id from bm_bookmarks
start with parent_id = :root_folder_id
connect by prior bookmark_id = parent_id)
and grantee_id <> :viewed_user_id"

db_dml turn_on_security_inheritance "update acs_objects set security_inherit_p = 't'
where object_id in (select bookmark_id from bm_bookmarks
start with parent_id = :root_folder_id
connect by prior bookmark_id = parent_id)"

ad_returnredirect "index?viewed_user_id=$viewed_user_id"




