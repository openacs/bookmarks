<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="direct_bookmark_permissions">      
      <querytext>
      select bookmark_id, local_title from bm_bookmarks
where acs_permission.permission_p(bookmark_id, acs.magic_object_id('registered_users'), 'read') <> :public_p
start with parent_id = :root_folder_id
connect by prior bookmark_id = parent_id
      </querytext>
</fullquery>

 
</queryset>
