<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="bm_packages">      
      <querytext>
      
    select site_node.url(node_id) as path
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
        from     (select /*+INDEX(bm_bookmarks bm_bookmarks_local_title_idx)*/ bookmark_id, url_id, local_title, folder_p, level lev, 
	          parent_id, owner_id, rownum ord_num from bm_bookmarks 
	          start with parent_id = :root_folder_id connect by prior bookmark_id = parent_id) b, 
	         bm_urls,
	         acs_objects
        where    owner_id       = :user_id
	and      acs_objects.object_id = b.bookmark_id
        and      b.url_id = bm_urls.url_id(+)
	order by ord_num
    
      </querytext>
</fullquery>

 
<fullquery name="bm_clean_up_session_data.delete_old_in_closed_p">      
      <querytext>
      delete from bm_in_closed_p where creation_date < (sysdate - 1)
      </querytext>
</fullquery>

 
</queryset>
