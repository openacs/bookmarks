<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bookmark_ids_for_url">      
      <querytext>

select bookmark_id
    from (select bookmark_id, url_id from bm_bookmarks
                        start with parent_id = :root_folder_id 
                        connect by prior bookmark_id = parent_id) bm
    where acs_permission__permission_p(bm.bookmark_id, :browsing_user_id, 'delete') = 't'
    and bm.url_id = :url_id
      </querytext>
</fullquery>

 
<fullquery name="delete_dead_link">      
      <querytext>

	begin
	perform bookmark__delete (
	bookmark_id => :bookmark_id
	);       
        end;
      </querytext>
</fullquery>

 
<fullquery name="delete_dead_link">      
      <querytext>


	begin
	perform bookmark__delete (
	bookmark_id => :bookmark_id
	);       
        end;
      </querytext>
</fullquery>

 
</queryset>
