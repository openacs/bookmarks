<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="contained_bookmarks">      
      <querytext>
select local_title, tree_level(tree_sorkkey) as indentation 
from bm_bookmarks
where tree_sortkey like
(
	select tree_sortkey || ''%'' from bm_bookmarks
	where bookmark_id  = :bookmark_id 
)
order by tree_sortkey
      </querytext>
</fullquery>

 
</queryset>
