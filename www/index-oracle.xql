<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<partialquery name="index_order_by_name">
	<querytext>
		/*+INDEX(bm_bookmarks bm_bookmarks_local_title_idx)*/		
	</querytext>
</partialquery>

<partialquery name="index_order_by_access_date">
	<querytext>
		/*+INDEX_DESC(bm_bookmarks bm_bookmarks_access_date_idx)*/		
	</querytext>
</partialquery>


<partialquery name="private_select">
	<querytext>
		, bookmark.private_p(b.bookmark_id) as private_p
	</querytext>
</partialquery>

<fullquery name="bookmark_system_name">      
      <querytext>
      select acs_object.name(:package_id) from dual
      </querytext>
</fullquery>

 
<fullquery name="bookmarks_select">      
      <querytext>
         select b.bookmark_id, b.url_id, b.local_title as bookmark_title, b.folder_p, 
           u.complete_url, u.last_live_date, u.last_checked_date, 
           bm_in_closed_p.closed_p, 
           nvl(admin_view.object_id, 0) as admin_p,
           nvl(delete_view.object_id,0) as delete_p,
           b.lev as indentation
           $private_select
         from bm_urls u,
           (select $index_order bookmark_id, url_id, local_title, folder_p, level lev, parent_id, rownum ord_num 
            from bm_bookmarks start with bookmark_id = :root_folder_id connect by prior bookmark_id = parent_id) b,
           bm_in_closed_p,
           (select distinct object_id
            from all_object_party_privilege_map
            where party_id = :browsing_user_id and privilege = 'admin') admin_view,
           (select distinct object_id
            from all_object_party_privilege_map
            where party_id = :browsing_user_id and privilege = 'delete') delete_view
         where b.url_id = u.url_id (+)
           and bm_in_closed_p.bookmark_id = b.bookmark_id
           and bm_in_closed_p.in_closed_p = 'f'
           and bm_in_closed_p.in_closed_p_id = :in_closed_p_id
           and exists (select 1
                       from bm_bookmarks
                       where exists (select 1
                                     from all_object_party_privilege_map
                                     where object_id = bookmark_id and party_id = :browsing_user_id
                                       and privilege = 'read')
                       start with bookmark_id = b.bookmark_id connect by prior bookmark_id = parent_id)
           and b.bookmark_id <> :root_folder_id
           and b.bookmark_id = admin_view.object_id(+)
           and b.bookmark_id = delete_view.object_id(+)
         order by ord_num
      </querytext>
</fullquery>

<fullquery name="my_bookmarks_select">      
      <querytext>
        select b.bookmark_id, b.url_id, b.local_title as bookmark_title,
          u.complete_url, u.last_live_date, u.last_checked_date, 
          b.folder_p, 
          bm_in_closed_p.closed_p, 
          nvl(admin_view.object_id, 0) as admin_p,
          nvl(delete_view.object_id,0) as delete_p,
          b.lev as indentation
          $private_select
        from bm_urls u,
          (select $index_order bookmark_id, url_id, local_title, folder_p, level lev, parent_id, rownum ord_num 
           from bm_bookmarks
           start with bookmark_id = :root_folder_id connect by prior bookmark_id = parent_id) b,
          bm_in_closed_p,
          (select distinct object_id
           from all_object_party_privilege_map
           where party_id = :browsing_user_id and privilege = 'admin') admin_view,
          (select distinct object_id
           from all_object_party_privilege_map
           where party_id = :browsing_user_id and privilege = 'delete') delete_view
        where b.url_id = u.url_id (+)
          and bm_in_closed_p.bookmark_id = b.bookmark_id
          and bm_in_closed_p.in_closed_p = 'f'
          and bm_in_closed_p.in_closed_p_id = :in_closed_p_id
          and exists (select 1
                      from bm_bookmarks
                      where exists (select 1
                                    from all_object_party_privilege_map
                                    where object_id = bookmark_id and party_id  = :browsing_user_id
                                      and privilege = 'read')
                                    start with bookmark_id = b.bookmark_id connect by prior bookmark_id = parent_id)
          and b.bookmark_id <> :root_folder_id
          and b.bookmark_id = admin_view.object_id(+)
          and b.bookmark_id = delete_view.object_id(+)
        order by ord_num
      </querytext>
</fullquery>

 
</queryset>






