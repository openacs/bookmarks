<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bm_packages">      
      <querytext>
      
    select site_node__url(node_id) as path
    from   site_nodes
    where  object_id in (select package_id
                         from   apm_packages where package_key = 'bookmarks')

      </querytext>
</fullquery>

 
<fullquery name="bm_export_to_netscape.bm_info">      
      <querytext>

        select   b.bookmark_id, 
	         b.url_id, 
                 b.local_title, 
	         acs_objects.creation_date, 
	         b.parent_id,
                 bm_urls.complete_url, 
	         b.folder_p
        from     (select bookmark_id, url_id, local_title, folder_p, 
		  parent_id, owner_id from bm_bookmarks 
		  where tree_sortkey like
			(
			select tree_sortkey || '%'
			from bm_bookmarks
			where bookmark_id = :root_folder_id
			)
		 order by tree_sortkey) b left join bm_urls using (url_id),
	         acs_objects
        where    owner_id       = :user_id
	and      acs_objects.object_id = b.bookmark_id
	order by tree_sortkey
    
      </querytext>
</fullquery>

 
<fullquery name="bm_clean_up_session_data.delete_old_in_closed_p">      
      <querytext>
      delete from bm_in_closed_p where creation_date < (current_timestamp - 1)
      </querytext>
</fullquery>

 
</queryset>
