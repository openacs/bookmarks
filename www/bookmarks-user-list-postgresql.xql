<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bookmarks_of_other_users">      
      <querytext>

select u.first_names, 
u.last_name, 
b.owner_id as viewed_user_id, 
count(b.bookmark_id) as number_of_bookmarks
from    
cc_users u, 
(
	select o2.bookmark_id, o2.url_id, o2.folder_p, o2.owner_id
	from bm_bookmarks o1, bm_bookmarks o2
	where o1.parent_id = :package_id
	and o2.tree_sortkey between o1.tree_sortkey and tree_right(o1.tree_sortkey)
	order by o2.tree_sortkey
) b
where   u.object_id = b.owner_id
and     acs_permission__permission_p(b.bookmark_id, :browsing_user_id, 'read') = 't'
and     b.owner_id <> :browsing_user_id
and     b.folder_p = 'f'
and     b.bookmark_id <> :package_id
group by 
u.first_names, 
u.last_name, 
b.owner_id
order by number_of_bookmarks desc
      </querytext>
</fullquery>

 
</queryset>
