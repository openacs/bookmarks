<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="bm_folder_selection.folder_select">      
      <querytext>
      
    select /*+INDEX(bm_bookmarks bm_bookmarks_local_title_idx)*/ bookmark_id, 
    local_title,
    level as indentation
    from   bm_bookmarks
    where folder_p = 't'
    and owner_id = :user_id
    and bookmark_id <> :bookmark_id
    and parent_id <> :package_id
    and acs_permission.permission_p(bookmark_id, :user_id, 'write') = 't'
    $exclude_folders
    start with parent_id = :package_id
    connect by prior bookmark_id = parent_id
    
      </querytext>
</fullquery>

 
<fullquery name="bm_get_root_folder_id.fs_root_folder">      
      <querytext>
      
      begin
          :1 := bookmark.get_root_folder(
                package_id => :package_id,
                user_id    => :user_id);
      end;
      </querytext>
</fullquery>

 
<fullquery name="bm_user_can_write_in_some_folder_p.write_in_folders">      
      <querytext>
      select count(*) from bm_bookmarks
                     where owner_id = :viewed_user_id
                     and folder_p = 't'
                     and acs_permission.permission_p(bookmark_id, :browsing_user_id, 'write') = 't'
      </querytext>
</fullquery>

 
<fullquery name="bm_delete_permission_p.delete_permission_p">      
      <querytext>
      select count(*) from bm_bookmarks 
	where acs_permission.permission_p(bookmark_id, :browsing_user_id, 'delete') = 'f'
	start with bookmark_id = :bookmark_id
	connect by prior bookmark_id = parent_id
      </querytext>
</fullquery>

 
<fullquery name="bm_bookmark_private_p.bookmark_private_p">      
      <querytext>
      select bookmark.private_p(:bookmark_id) from dual
      </querytext>
</fullquery>

 
<fullquery name="bm_update_bookmark_private_p.update_private_p">      
      <querytext>
      
	    begin
	       bookmark.update_private_p(:bookmark_id, :private_p);
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="bm_initialize_in_closed_p.initialize_in_closed_p">      
      <querytext>
      
	    begin
	       bookmark.initialize_in_closed_p(:viewed_user_id, :in_closed_p_id);
	    end;
	
      </querytext>
</fullquery>

 
</queryset>
