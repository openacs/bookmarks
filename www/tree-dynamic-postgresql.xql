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
	select  
		bookmark_id, url_id, local_title, folder_p, 
              	parent_id, owner_id, tree_sortkey from bm_bookmarks 
		where tree_sortkey like
			(
			select tree_sortkey || '%'
			from bm_bookmarks
			where bookmark_id = :root_id
			)
		order by tree_sortkey
	) 
	b left join bm_urls using (url_id) 
where exists 
	(
	select 1 from bm_bookmarks 
	where tree_sortkey like
		(
		select tree_sortkey || '%'
		from bm_bookmarks
		where bookmark_id = b.bookmark_id
		)
	and acs_permission__permission_p(bookmark_id, :user_id, 'read') = 't'
	)
and      b.bookmark_id <> :root_id
order by tree_sortkey

</querytext>
</fullquery>

 
</queryset>

