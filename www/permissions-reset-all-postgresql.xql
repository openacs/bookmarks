<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="direct_bookmark_permissions">      
      <querytext>

         select bm.bookmark_id, bm.local_title, bm.tree_sortkey
         from bm_bookmarks bm, bm_bookmarks bm2
         where bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
           and bm2.bookmark_id = :root_folder_id
           and acs_permission__permission_p(bookmark_id, acs__magic_object_id('registered_users'), 'read') <> :public_p
	 order by bm.tree_sortkey

      </querytext>
</fullquery>

 
</queryset>
