<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bookmark_items">      
      <querytext>
select   
	b.bookmark_id, b.url_id, b.local_title, last_live_date, 
	last_checked_date, b.parent_id, complete_url, b.folder_p
from     
	(
	select bm.bookmark_id, bm.url_id, bm.local_title, bm.folder_p, 
          bm.parent_id, bm.owner_id, bm.tree_sortkey
        from bm_bookmarks bm, bm_bookmarks bm2
        where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
          and bm2.bookmark_id = :root_id
	) 
	b left join bm_urls using (url_id) 
where exists 
	(
	select 1 from bm_bookmarks bm, bm_bookmarks bm2
	where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
          and bm2.bookmark_id = b.bookmark_id
	)
	and acs_permission__permission_p(bookmark_id, :user_id, 'read') = 't'
	)
and      b.bookmark_id <> :root_id
order by b.tree_sortkey

</querytext>
</fullquery>

 
</queryset>

