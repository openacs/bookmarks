<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="update_access_date">      
      <querytext>
      update bm_bookmarks set last_access_date = sysdate where bookmark_id = :bookmark_id
or bookmark_id in (select bookmark_id from bm_bookmarks 
start with bookmark_id = (select parent_id from bm_bookmarks where bookmark_id = :bookmark_id) 
connect by prior parent_id = bookmark_id)
      </querytext>
</fullquery>

 
</queryset>
