<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="popular_hosts">      
      <querytext>
      
select host_url, count(*) as n_bookmarks
	from 
	(
		select 	o2.bookmark_id, o2.url_id
		from bm_bookmarks o1, bm_bookmarks o2
		where 
			o1.parent_id = :root_folder_id
			and o2.tree_sortkey >= o1.tree_sortkey
			and o2.tree_sortkey like (o1.tree_sortkey || '%')
		order by o2.tree_sortkey
	) b join bm_urls using (url_id)
        where acs_permission__permission_p(b.bookmark_id, :browsing_user_id, 'read') = 't'
group by host_url
order by n_bookmarks desc

      </querytext>
</fullquery>

 
<fullquery name="popular_urls">      
      <querytext>
      
    select complete_url as local_title, 
           complete_url, count(*) as n_bookmarks
	from 
	(
		select 	o2.bookmark_id, o2.url_id
		from bm_bookmarks o1, bm_bookmarks o2
		where 
			o1.parent_id = :root_folder_id
			and o2.tree_sortkey >= o1.tree_sortkey
			and o2.tree_sortkey like (o1.tree_sortkey || '%')
		order by o2.tree_sortkey
	) b join bm_urls using (url_id)
        where acs_permission__permission_p(b.bookmark_id, :browsing_user_id, 'read') = 't' 
group by complete_url, local_title
    order by n_bookmarks desc

      </querytext>
</fullquery>


 
</queryset>
