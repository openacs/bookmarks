<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="delete_individual_permissions">      
      <querytext>

delete from 
	acs_permissions 
where 
	object_id in 
	(
	select bookmark_id from bm_bookmarks
	where tree_sortkey like
		(
		select tree_sortkey || '%'
		from bm_bookmarks
		where bookmark_id = :root_folder_id
		)
	)
and grantee_id <> :viewed_user_id
      </querytext>
</fullquery>

 
<fullquery name="turn_on_security_inheritance">      
      <querytext>

update 
	acs_objects 
set 
	security_inherit_p = 't'
where 
	object_id in 
	(
	select bookmark_id from bm_bookmarks
	where tree_sortkey like
		(
		select tree_sortkey || '%'
		from bm_bookmarks
		where bookmark_id = :root_folder_id
		)
	)

      </querytext>
</fullquery>

 
</queryset>
