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
		select bookmark_id, url_id from bm_bookmarks
		where tree_sortkey like 
			       (
				select tree_sortkey || '%' from bm_bookmarks
				where bookmark_id= :root_folder_id
			       )
			       order by tree_sortkey
	) bm on (bm.url_id=bm_urls.url_id)
      
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
