<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="bookmark_ids_for_url">      
      <querytext>
      select bookmark_id
    from (select bookmark_id, url_id from bm_bookmarks
                        start with parent_id = :root_folder_id 
                        connect by prior bookmark_id = parent_id) bm
    where acs_permission.permission_p(bm.bookmark_id, :browsing_user_id, 'delete') = 't'
    and bm.url_id = :url_id
      </querytext>
</fullquery>

 
<fullquery name="delete_dead_link">      
      <querytext>
      
	begin
	bookmark.del (
	bookmark_id => :bookmark_id
	);       
        end;
      </querytext>
</fullquery>

 
<fullquery name="delete_dead_link">      
      <querytext>
      
	begin
	bookmark.del (
	bookmark_id => :bookmark_id
	);       
        end;
      </querytext>
</fullquery>

 
</queryset>
