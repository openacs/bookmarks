<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>
<if @head_contents@ not nil><property name="header_stuff">@head_contents@</property></if>
<if @signatory@ not nil><property name="signatory">@signatory@</property></if>
<h2>@page_title@</h2>
@context_bar@
<hr>
<slave>