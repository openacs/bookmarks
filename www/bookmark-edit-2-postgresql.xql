<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="insert_or_update_url">      
      <querytext>
	declare
	   v_url_id integer;
	begin
	v_url_id := url__insert_or_update (
    	:local_title,
    	:host_url,
    	:complete_url,
	null,
	null,
    	:creation_user,
    	:creation_ip,
	null
    );
	return v_url_id;
    end;
      </querytext>
</fullquery>

 
<fullquery name="update_in_closed_p_all_users">      
      <querytext>

         select bookmark__update_in_closed_p_all_users(:bookmark_id, :parent_id)

      </querytext>
</fullquery>

 
</queryset>



