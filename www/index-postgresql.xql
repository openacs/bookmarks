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
        select b.bookmark_id, b.url_id, b.local_title as bookmark_title,
          u.complete_url, u.last_live_date, u.last_checked_date, 
          b.folder_p, 
          bm_in_closed_p.closed_p, 
          acs_permission__permission_p(b.bookmark_id, :browsing_user_id, 'admin') as admin_p,
          acs_permission__permission_p(b.bookmark_id, :browsing_user_id, 'delete') as delete_p,
          b.lev as indentation
          $private_select
        from 
          bm_in_closed_p cross join
          (bm_urls u right join (
	         select $index_order bm.bookmark_id, bm.url_id, bm.local_title, bm.folder_p, 
 	                tree_level(bm.tree_sortkey) as lev, bm.parent_id, bm.tree_sortkey 
	         from bm_bookmarks bm, bm_bookmarks bm2
	         where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
                 and bm2.bookmark_id = :root_folder_id
              ) b on (u.url_id = b.url_id) )
          where bm_in_closed_p.bookmark_id = b.bookmark_id
          and bm_in_closed_p.in_closed_p = 'f'
          and bm_in_closed_p.in_closed_p_id = :in_closed_p_id
          and exists (select 1
                      from bm_bookmarks bm, bm_bookmarks bm2
                      where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
                      and bm2.bookmark_id = b.bookmark_id
  	              and acs_permission__permission_p(bm.bookmark_id, :browsing_user_id, 'read')
		      )
          and b.bookmark_id <> :root_folder_id
        order by b.tree_sortkey
      </querytext>
</fullquery>

<fullquery name="my_bookmarks_select">      
      <querytext>
        select 
          b.bookmark_id, b.url_id, b.local_title as bookmark_title,
          u.complete_url, u.last_live_date, u.last_checked_date, 
          b.folder_p, bm_in_closed_p.closed_p, 
          b.bookmark_id as admin_p, b.bookmark_id as delete_p,
          b.lev as indentation
          $private_select
        from bm_in_closed_p cross join ( 
	  bm_urls u right join (select $index_order bm.bookmark_id, bm.url_id, bm.local_title, bm.folder_p, 
 		                  tree_level(bm.tree_sortkey) as lev, bm.parent_id, bm.tree_sortkey 
	                        from bm_bookmarks bm, bm_bookmarks bm2
	                        where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
			          and bm2.bookmark_id = :root_folder_id) b on (u.url_id=b.url_id))
        where bm_in_closed_p.bookmark_id = b.bookmark_id
          and bm_in_closed_p.in_closed_p = 'f'
          and bm_in_closed_p.in_closed_p_id = :in_closed_p_id
          and b.bookmark_id <> :root_folder_id
        order by b.tree_sortkey
      </querytext>
</fullquery>

<fullquery name="bm_info">      
      <querytext>

        select   b.bookmark_id, 
	         b.url_id, 
                 b.local_title, 
	         acs_objects.creation_date, 
	         b.parent_id,
                 bm_urls.complete_url, 
	         b.folder_p
        from     (select bm.bookmark_id, bm.url_id, bm.local_title, bm.folder_p, 
		  bm.parent_id, bm.owner_id, bm.tree_sortkey from bm_bookmarks bm, bm_bookmarks bm2
		  where bm2.bookmark_id = :root_folder_id
                    and bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
		 ) b left join bm_urls using (url_id),
	         acs_objects
        where    owner_id       = :user_id
	and      acs_objects.object_id = b.bookmark_id
	and	 b.bookmark_id != :root_folder_id
	order by b.tree_sortkey
    
      </querytext>
</fullquery>
 
</queryset>


