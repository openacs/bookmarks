<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="popular_hosts">      
      <querytext>
      
select distinct host_url,
       (
	select count(*) 
	from 
	(
		select 	o2.bookmark_id, o2.url_id
		from bm_bookmarks o1, bm_bookmarks o2
		where 
			o1.parent_id = :root_folder_id
			and o2.tree_sortkey >= o1.tree_sortkey
			and o2.tree_sortkey like (o1.tree_sortkey || '%')
		order by o2.tree_sortkey
	) b 
	where b.url_id = bm_urls.url_id
        and acs_permission__permission_p(b.bookmark_id, :browsing_user_id, 'read') = 't') as n_bookmarks
from  bm_urls
order by n_bookmarks desc

      </querytext>
</fullquery>

 
<fullquery name="popular_urls">      
      <querytext>
      
    select coalesce(url_title, complete_url) as local_title, 
           complete_url, 
                      (
	select count(*) 
	from 
	(
		select 	o2.bookmark_id, o2.url_id
		from bm_bookmarks o1, bm_bookmarks o2
		where 
			o1.parent_id = :root_folder_id
			and o2.tree_sortkey >= o1.tree_sortkey
			and o2.tree_sortkey like (o1.tree_sortkey || '%')
		order by o2.tree_sortkey
	) b 
	where b.url_id = bm_urls.url_id
        and acs_permission__permission_p(b.bookmark_id, :browsing_user_id, 'read') = 't') as n_bookmarks
    from   bm_urls
    order by n_bookmarks desc

      </querytext>
</fullquery>


 
</queryset>
