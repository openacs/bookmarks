<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="toggle_open_close">      
      <querytext>
begin
	perform bookmark__toggle_open_close (:bookmark_id,:in_closed_p_id);
	
	return 0;
end;
      </querytext>
</fullquery>

 
<fullquery name="toggle_open_close_all">      
	<querytext>
begin
	perform bookmark__toggle_open_close_all(
				:in_closed_p_id,
 				:closed_p,
   				bookmark__get_root_folder(:package_id,:viewed_user_id)
    				);
	
	return 0;
end;
      </querytext>
</fullquery>

 
</queryset>
