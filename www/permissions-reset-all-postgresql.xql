<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="direct_bookmark_permissions">      
      <querytext>

select 
	bookmark_id, local_title 
from 
	bm_bookmarks
where 
	tree_sortkey like
		(
		select tree_sortkey || '%'
		from bm_bookmarks
		where bookmark_id = :root_folder_id
			)
	order by tree_sortkey
and
	acs_permission__permission_p(bookmark_id, acs__magic_object_id('registered_users'), 'read') <> :public_p

      </querytext>
</fullquery>

 
</queryset>
