<?xml version="1.0"?>
<queryset>

<fullquery name="dbclick_check">      
      <querytext>
      
select count(bookmark_id) as n_existing
from   bm_bookmarks 
where  bookmark_id = :bookmark_id
      </querytext>
</fullquery>

 
<fullquery name="n_dp_folder">      
      <querytext>
      
	    select count(*) from bm_bookmarks
	    where  owner_id = :viewed_user_id
	    and    parent_id = :parent_id
	    and    folder_p = 't'
	    and    local_title = :local_title
      </querytext>
</fullquery>

 
<fullquery name="bm_parent">      
      <querytext>
      
	    select bookmark_id
	    from   bm_bookmarks
	    where  folder_p = 't'
	    and    owner_id = :user_id
	    and    local_title = :local_title
      </querytext>
</fullquery>

 
<fullquery name="bm_dp_url">      
      <querytext>
      
		    select url_id
		    from   bm_urls
		    where  complete_url = :complete_url
      </querytext>
</fullquery>

 
<fullquery name="dp">      
      <querytext>
      
		select count(bookmark_id) 
		from   bm_bookmarks
		where  url_id = :url_id
		and    owner_id = :viewed_user_id
		and    parent_id = :parent_id
      </querytext>
</fullquery>

 
<fullquery name="">      
      <querytext>
      
			select count(bookmark_id) 
			from   bm_bookmarks 
			where bookmark_id = :bookmark_id
      </querytext>
</fullquery>

 
</queryset>
