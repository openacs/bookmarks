<?xml version="1.0"?>
<queryset>

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
        from   bm_bookmarks left join bm_urls using (url_id), parties 
        where  bookmark_id = :bookmark_id
        and    bm_bookmarks.owner_id = parties.party_id
      </querytext>
</fullquery>

 
</queryset>

