<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bookmark_ids_for_url">      
      <querytext>

select bookmark_id
from 
(
	select bookmark_id, url_id 
	from bm_bookmarks
	where tree_sortkey like
	(
		select tree_sortkey || '%'
		from bm_bookmarks
		where parent_id = :root_folder_id 
	)
	order by tree_sortkey
) bm
where acs_permission__permission_p(bm.bookmark_id, :browsing_user_id, 'delete') = 't'
and bm.url_id = :url_id
      </querytext>
</fullquery>

 
<fullquery name="delete_dead_link">      
      <querytext>
      FIX ME PLSQL
FIX ME PLSQL

	begin
	bookmark__delete (
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
	return 0;       
end;
      </querytext>
</fullquery>

 
</queryset>
