<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bookmark_admin_p">
	<querytext>
	select 
	acs_permission__permission_p(:bookmark_id, :browsing_user_id, 'admin')
	</querytext>
</fullquery>


 
</queryset>
