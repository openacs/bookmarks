<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="bookmark_items">      
      <querytext>
      
    select   b.bookmark_id, 
             b.url_id, 
             b.local_title, 
             last_live_date, 
             last_checked_date,
             b.parent_id, 
             complete_url, 
             b.folder_p
    from     (select /*+INDEX(bm_bookmarks bm_bookmarks_local_title_idx)*/ 
              bookmark_id, url_id, local_title, folder_p, 
              level lev, parent_id, owner_id, rownum as ord_num 
              from bm_bookmarks start with bookmark_id = :root_id 
              connect by prior bookmark_id = parent_id) b, 
             bm_urls
    where exists (select 1 from bm_bookmarks where acs_permission.permission_p(bookmark_id, :user_id, 'read') = 't'
            start with bookmark_id = b.bookmark_id connect by prior bookmark_id = parent_id)
    and      b.bookmark_id <> :root_id
    and      b.url_id = bm_urls.url_id(+)
    order by ord_num

      </querytext>
</fullquery>

 
</queryset>
