<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<partialquery name="index_order_by_name">
	<querytext>

	</querytext>
</partialquery>

<partialquery name="index_order_by_access_date">
	<querytext>

	</querytext>
</partialquery>


<partialquery name="private_select">
	<querytext>
		, bookmark__private_p(b.bookmark_id) as private_p
	</querytext>
</partialquery>

<fullquery name="bookmark_system_name">      
      <querytext>
      select acs_object__name(:package_id) 
      </querytext>
</fullquery>

 
<fullquery name="bookmarks_select">      
      <querytext>
select b.bookmark_id,
b.url_id,
b.local_title as bookmark_title,
u.complete_url,
u.last_live_date, 
u.last_checked_date, 
b.folder_p, 
bm_in_closed_p.closed_p, 
coalesce(admin_view.object_id, 0) as admin_p,
coalesce(delete_view.object_id,0) as delete_p,
b.lev as indentation
$private_select
from 
bm_in_closed_p cross join
((( bm_urls u right join (
	select $index_order bookmark_id, url_id, local_title, folder_p, 
 	tree_level(tree_sortkey) as lev, parent_id, tree_sortkey 
	from bm_bookmarks
	where tree_sortkey like
	(
		select tree_sortkey || '%'
		from bm_bookmarks
		where bookmark_id = :root_folder_id
	)
	order by tree_sortkey
) 
b on (u.url_id=b.url_id)) left join
(
	select object_id from acs_object_party_privilege_map
 	where party_id in (:browsing_user_id, -1) and privilege = 'admin'
) admin_view on (admin_view.object_id=b.bookmark_id)) left join
(
	select object_id from acs_object_party_privilege_map
 	where party_id in (:browsing_user_id, -1) and privilege = 'delete'
) delete_view on (delete_view.object_id = b.bookmark_id))
where bm_in_closed_p.bookmark_id = b.bookmark_id
and bm_in_closed_p.in_closed_p = 'f'
and bm_in_closed_p.in_closed_p_id = :in_closed_p_id
and exists 
(
	select 1 from bm_bookmarks where exists 
	(
		select 1 from acs_object_party_privilege_map 
		where object_id = bookmark_id and party_id in 
		(:browsing_user_id, -1)
		and privilege = 'read'
	)
	and tree_sortkey like
		(
		select tree_sortkey || '%'
		from bm_bookmarks
		where bookmark_id = b.bookmark_id
		)
	order by tree_sortkey 	
)
and b.bookmark_id <> :root_folder_id
order by b.tree_sortkey
      </querytext>
</fullquery>

 
</queryset>


