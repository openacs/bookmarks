<?xml version="1.0"?>
<queryset>

<fullquery name="count_url">      
      <querytext>
      
    select count(*)
    from   bm_urls
    where  complete_url = :complete_url 
      </querytext>
</fullquery>

 
<fullquery name="new_url_id">      
      <querytext>
      select url_id 
                                      from   bm_urls 
                                      where  complete_url= :complete_url
      </querytext>
</fullquery>

 
<fullquery name="update_url_meta_info">      
      <querytext>
      update bm_urls set url_title= :url_title,
	    meta_description= :meta_description,
	    meta_keywords= :meta_keywords
            where url_id = :url_id
      </querytext>
</fullquery>

 
</queryset>

