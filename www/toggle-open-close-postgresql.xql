<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="toggle_open_close">      
      <querytext>
begin
	perform bookmark__toggle_open_close (:bookmark_id,:browsing_user_id);
end;
      </querytext>
</fullquery>

 
<fullquery name="toggle_open_close_all">      
	<querytext>
begin
	perform bookmark__toggle_open_close_all(
				:browsing_user_id,
 				:closed_p,
   				bookmark__get_root_folder(:package_id,:viewed_user_id)
    				);
end;
      </querytext>
</fullquery>

 
</queryset>
