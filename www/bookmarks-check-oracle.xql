<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>


<partialquery name="set_last_live_date_to_now">
	<querytext>
              sysdate
	</querytext>
</partialquery>
 

<fullquery name="bookmark_list">      
      <querytext>
      
select url_id,
       complete_url,
       nvl(url_title, complete_url) as url_title
       from bm_urls
       where exists (select 1 from (select bookmark_id, url_id from bm_bookmarks
                                                     start with parent_id = :root_folder_id 
                                                     connect by prior bookmark_id = parent_id) bm
                                      where bm.url_id = bm_urls.url_id
                                      and acs_permission.permission_p(bm.bookmark_id, :browsing_user_id, 'delete')= 't' )
      </querytext>
</fullquery>

 
<fullquery name="bookmark_update_last_checked">      
      <querytext>
      
    update bm_urls 
    set    last_checked_date = sysdate,

    url_title= :title,
    meta_description= :description,
    meta_keywords= :keywords

    $last_live_clause

    where  url_id = :url_id
      </querytext>
</fullquery>

 
</queryset>
