<?xml version="1.0"?>
<queryset>

<fullquery name="bookmark_admin_p">
	<querytext>
	select 
	acs_permission.permission_p(:bookmark_id, :browsing_user_id, 'admin') 
	from dual
	</querytext>
</fullquery>

<fullquery name="folder_p">
	<querytext>
	 select folder_p from bm_bookmarks where bookmark_id = :bookmark_id
	</querytext>
</fullquery>

<fullquery name="inheritance_p">
	<querytext>
	select security_inherit_p from acs_objects where object_id = :bookmark_id
	</querytext>
</fullquery>


<fullquery name="bookmark_edit">      
      <querytext>
 	select local_title,
               owner_id,
               complete_url, 
               folder_p,
               parent_id, 
               bookmark_id
        from   bm_bookmarks left join bm_urls using (url_id)
        where  bookmark_id = :bookmark_id
      </querytext>
</fullquery>

 
</queryset>

