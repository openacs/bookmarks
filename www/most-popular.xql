<?xml version="1.0"?>
<queryset>

<fullquery name="popular_hosts">      
      <querytext>
      
    select unique host_url,
           $count_select_query as n_bookmarks
    from  bm_urls
    order by n_bookmarks desc

      </querytext>
</fullquery>

 
<fullquery name="popular_urls">      
      <querytext>
      
    select coalesce(url_title, complete_url) as local_title, 
           complete_url, 
           $count_select_query as n_bookmarks
    from   bm_urls
    order by n_bookmarks desc

      </querytext>
</fullquery>

 
</queryset>
