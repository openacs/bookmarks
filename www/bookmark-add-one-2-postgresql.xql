<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="url_add">      
      <querytext>
	declare
	   v_url_id integer;
	begin
	   v_url_id := url__new (
           		:url_id,
           		:url_title,
	   		:host_url,
	   		:complete_url,
           		:meta_keywords,
           		:meta_description,
           		:viewed_user_id,
           		:creation_ip,
			null
			);
	return v_url_id;
	end;
      </querytext>
</fullquery>

 
<fullquery name="bookmark_add">      
      <querytext>
begin

	perform	     bookmark__new (
		    :bookmark_id,
		    :viewed_user_id,
		    :url_id,
		    :local_title,
		    FALSE,
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
