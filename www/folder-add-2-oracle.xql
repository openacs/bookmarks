<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="bookmark_add">      
      <querytext>
      
declare
dummy_var integer;
begin
dummy_var := bookmark.new (
bookmark_id => :bookmark_id,
owner_id    => :viewed_user_id,
local_title => :local_title,
parent_id   => :parent_id,
folder_p    => :folder_p,
creation_user => :user_id,
creation_ip => :creation_ip
);       
end;
      </querytext>
</fullquery>

 
</queryset>
