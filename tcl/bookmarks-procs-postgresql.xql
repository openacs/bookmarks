<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<partialquery name="exclude_folders">
	<querytext>
		and bookmark_id not in 
		(
		select bm.bookmark_id from bm_bookmarks bm, bm_bookmarks bm2
		where bm.folder_p = 't' 
		  and bm.owner_id = :user_id 
		  and bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
                  and bm2.parent_id = :package_id
                  and bm2.owner_id = :user_id
		)
	</querytext>
</partialquery>



<fullquery name="bm_folder_selection.folder_select">      
      <querytext>
    select bm.bookmark_id, bm.local_title, tree_level(bm.tree_sortkey) as indentation
    from   bm_bookmarks bm, bm_bookmarks bm2
    where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
      and bm2.parent_id = :package_id
      and bm2.owner_id = :user_id
      and bm.folder_p = 't'
      and bm.owner_id = :user_id
      and bm.bookmark_id <> :bookmark_id
      and bm.parent_id <> :package_id
      and acs_permission__permission_p(:bookmark_id, :user_id, 'write') = 't'
      $exclude_folders
    order by bm.tree_sortkey
      </querytext>
</fullquery>

 
<fullquery name="bm_get_root_folder_id.fs_root_folder">      
      <querytext>

          select bookmark__get_root_folder (:package_id, :user_id);

      </querytext>
</fullquery>

 
<fullquery name="bm_user_can_write_in_some_folder_p.write_in_folders">      
      <querytext>
      select count(*) from bm_bookmarks
                     where owner_id = :viewed_user_id
                     and folder_p = 't'
                     and acs_permission__permission_p(bookmark_id, :browsing_user_id, 'write')
      </querytext>
</fullquery>

 
<fullquery name="bm_delete_permission_p.delete_permission_p">      
      <querytext>
select count(*) from bm_bookmarks bm, bm_bookmarks bm2
    where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
      and bm2.bookmark_id = :bookmark_id
      and not acs_permission__permission_p(bm.bookmark_id, :browsing_user_id, 'delete')
      </querytext>
</fullquery>

 
<fullquery name="bm_bookmark_private_p.bookmark_private_p">      
      <querytext>
      select bookmark__private_p(:bookmark_id) 
      </querytext>
</fullquery>

 
<fullquery name="bm_update_bookmark_private_p.update_private_p">      
      <querytext>

	select bookmark__update_private_p(:bookmark_id, :private_p)
	
      </querytext>
</fullquery>

 
<fullquery name="bm_initialize_in_closed_p.initialize_in_closed_p">      
      <querytext>

	select bookmark__initialize_in_closed_p (:viewed_user_id, :in_closed_p_id, :package_id);
	
      </querytext>
</fullquery>

 
</queryset>


