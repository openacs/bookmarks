ad_page_contract {
    Lists all users who have bookmarks in the system
    accompanied by the number of bookmarks that are 
    readable by the browsing user.
    
    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id:
}

set page_title "View other users bookmarks"

set context_bar_args "\"$page_title\""

set browsing_user_id [ad_conn user_id]

set package_id [ad_conn package_id]

db_multirow user_list bookmarks_of_other_users "select u.first_names, 
            u.last_name, 
            b.owner_id as viewed_user_id, 
            count(b.bookmark_id) as number_of_bookmarks
    from    cc_users u, (select bookmark_id, url_id, folder_p, owner_id from bm_bookmarks 
                    start with parent_id = :package_id connect by prior bookmark_id = parent_id) b
    where   u.object_id = b.owner_id
    and     acs_permission.permission_p(b.bookmark_id, :browsing_user_id, 'read') = 't'
    and     b.owner_id <> :browsing_user_id
    and     b.folder_p = 'f'
    and     b.bookmark_id <> :package_id
    group by u.first_names, 
             u.last_name, 
             b.owner_id
    order by number_of_bookmarks desc"


ad_return_template













