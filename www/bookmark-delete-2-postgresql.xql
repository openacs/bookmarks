<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bookmark_delete">      
      <querytext>
begin
    perform
      bookmark__delete 
	(
      	:bookmark_id
	);
	return 0;       
 end;
      </querytext>
</fullquery>

 
</queryset>
