<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="update_access_date">      
      <querytext>

	update bm_bookmarks set last_access_date = current_timestamp 
        where bookmark_id in 
		(
		select bm.bookmark_id from bm_bookmarks bm, bm_bookmarks bm2
		where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey) 
		  and bm2.bookmark_id = :bookmark_id
		)
      </querytext>
</fullquery>

 
</queryset>

