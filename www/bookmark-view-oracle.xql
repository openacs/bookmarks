<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="bookmark_view">      
      <querytext>
	select local_title,
               email,
               owner_id,
               complete_url, 
               bookmark_id,
               meta_keywords,
               meta_description,
               url_title
        from   bm_bookmarks, 
               bm_urls,
               parties
        where  bookmark_id = :bookmark_id
        and    bm_bookmarks.url_id = bm_urls.url_id(+)
        and    bm_bookmarks.owner_id = parties.party_id      
	</querytext>
</fullquery>

 
</queryset>






