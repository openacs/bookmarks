<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="update_access_date">      
      <querytext>

	update bm_bookmarks set last_access_date = current_timestamp 
        where bookmark_id = :bookmark_id
        or bookmark_id in 
		(
		select bookmark_id from bm_bookmarks 
		where tree_sortkey like 
		(
			select tree_sortkey || '%'
			from bm_bookmarks where 
			bookmark_id = :bookmark_id
		)
		)
      </querytext>
</fullquery>

 
</queryset>

