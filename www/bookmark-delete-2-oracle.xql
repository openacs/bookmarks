<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="bookmark_delete">      
      <querytext>
      
    begin
      bookmark.delete (
       bookmark_id => :bookmark_id
	);       
 end;
      </querytext>
</fullquery>

 
</queryset>
