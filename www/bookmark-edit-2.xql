<?xml version="1.0"?>
<queryset>

<fullquery name="update_bookmark">      
      <querytext>
      update bm_bookmarks set local_title = :local_title, parent_id = :parent_id
                        $url_clause
                        where bookmark_id = :bookmark_id
      </querytext>
</fullquery>

 
<fullquery name="update_context_id">      
      <querytext>
      update acs_objects set context_id = :parent_id where object_id = :bookmark_id
      </querytext>
</fullquery>

<partialquery name="url_clause">
      <querytext>
         , url_id = :url_id
      </querytext>
</partialquery>
 
</queryset>
