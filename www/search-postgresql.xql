<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bookmark_search_user">      
      <querytext>

    select   bookmark_id, 
             complete_url,
             coalesce(local_title, url_title) as title, 
	     bm_bookmarks_get_folder_names(bookmark_id, null) as folder_names,
	     tree_sortkey,
             meta_keywords, 
             meta_description
    from     (select bm.bookmark_id, bm.url_id, bm.local_title, bm.folder_p, bm.owner_id, bm.tree_sortkey
              	from bm_bookmarks bm, bm_bookmarks bm2
		where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
                  and bm2.bookmark_id = :root_folder_id
		) b, 
             bm_urls
    where    owner_id = :browsing_user_id 
    and      folder_p = 'f'
    and      b.url_id = bm_urls.url_id 
    and      b.bookmark_id <> :root_folder_id
    and     (    upper(local_title)      like :search_pattern
              or upper(url_title)        like :search_pattern
              or upper(complete_url)     like :search_pattern
              or upper(meta_keywords)    like :search_pattern
              or upper(meta_description) like :search_pattern)
    order by tree_sortkey

      </querytext>
</fullquery>

 
<fullquery name="bookmark_search_other">      
      <querytext>

select	distinct complete_url,
      	bookmark_id,
      	coalesce(local_title, url_title) as title, 
	bm_bookmarks_get_folder_names(bookmark_id, null) as folder_names,
	tree_sortkey,
      	meta_keywords, 
      	meta_description, 
     	folder_p,
    	acs_permission__permission_p(bookmark_id, :browsing_user_id, 'admin') as admin_p
from
	(
		select 	o2.bookmark_id, o2.url_id, o2.local_title, 
			o2.folder_p, o2.owner_id, o2.tree_sortkey
		from bm_bookmarks o1, bm_bookmarks o2
		where 
			o1.parent_id = :package_id
			and o2.tree_sortkey between o1.tree_sortkey and tree_right(o1.tree_sortkey)
		order by o2.tree_sortkey
	) b join bm_urls using (url_id) 
where    owner_id <> :browsing_user_id
and      acs_permission__permission_p(bookmark_id, :browsing_user_id, 'read') = 't'
and  	folder_p  = 'f' 
and	(   
	upper(local_title)      like :search_pattern
       	or upper(url_title)        like :search_pattern
       	or upper(complete_url)     like :search_pattern
      	or upper(meta_keywords)    like :search_pattern
      	or upper(meta_description) like :search_pattern
	)
order by tree_sortkey

      </querytext>
</fullquery>

 
</queryset>
