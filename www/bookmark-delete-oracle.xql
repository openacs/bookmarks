<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="contained_bookmarks">      
      <querytext>
      select local_title, level as indentation 
from bm_bookmarks start with bookmark_id = :bookmark_id 
connect by prior bookmark_id = parent_id
      </querytext>
</fullquery>

 
</queryset>
