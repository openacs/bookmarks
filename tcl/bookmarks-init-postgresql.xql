<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bm_packages">      
      <querytext>
      
    select site_node__url(node_id) as path
    from   site_nodes
    where  object_id in (select package_id
                         from   apm_packages where package_key = 'bookmarks')

      </querytext>
</fullquery>

<fullquery name="bm_clean_up_session_data.delete_old_in_closed_p">      
      <querytext>
      delete from bm_in_closed_p where creation_date < (current_timestamp - interval '1 day')
      </querytext>
</fullquery>

 
</queryset>
