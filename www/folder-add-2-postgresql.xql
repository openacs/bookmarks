<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bookmark_add">      
      <querytext>
begin

	perform	     bookmark__new (
		    :bookmark_id,
		    :viewed_user_id,
		    null,
		    :local_title,
		    :folder_p,
		    :parent_id,
		    null,
		    :user_id,
		    :creation_ip,
		    null);
   	return '';
end;
      </querytext>
</fullquery>

 
</queryset>
