<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="bookmarks_of_other_users">      
      <querytext>
      select u.first_names, 
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
    order by number_of_bookmarks desc
      </querytext>
</fullquery>

 
</queryset>
