<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bookmark_list">      
      <querytext>

	select bm_urls.url_id,
       	complete_url,
       	coalesce(url_title, complete_url) as url_title
       	from bm_urls join
	(
		select bm.bookmark_id, bm.url_id, bm.tree_sortkey
                from bm_bookmarks bm, bm_bookmarks bm2
		where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey) 
                  and bm2.parent_id = :root_folder_id
	) bm on (bm.url_id=bm_urls.url_id)
        where acs_permission__permission_p(bm.bookmark_id, :browsing_user_id,
       'delete')= 't' 
        order by bm.tree_sortkey
      
	</querytext>
</fullquery>

<partialquery name="set_last_live_date_to_now">
	<querytext>
		now()
	</querytext>
</partialquery>
 
<fullquery name="bookmark_update_last_checked">      
      <querytext>
      
    update bm_urls 
    set    last_checked_date = current_timestamp,

    url_title= :title,
    meta_description= :description,
    meta_keywords= :keywords

    $last_live_clause

    where  url_id = :url_id
      </querytext>
</fullquery>

 
</queryset>
