<?xml version="1.0"?>
<queryset>

<fullquery name="user_exists">      
      <querytext>
      select 1 from parties where party_id = :viewed_user_id
      </querytext>
</fullquery>

 
<fullquery name="user_name">      
      <querytext>
      select first_names || ' ' || last_name from cc_users where object_id = :viewed_user_id
      </querytext>
</fullquery>
 
</queryset>
