<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="contained_bookmarks">      
      <querytext>
select bm.local_title, tree_level(bm.tree_sortkey) as indentation 
from bm_bookmarks bm, bm_bookmarks bm2
where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
  and bm2.bookmark_id = :bookmark_id
order by bm.tree_sortkey
      </querytext>
</fullquery>

 
</queryset>
