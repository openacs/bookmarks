<if @signatory@ nil>
  <% # Set a default email address to sign the bottom of each page.
     set signatory [ad_parameter -package_id [ad_acs_kernel_id] SystemOwner "admin@yourservername"] %>
</if>

<if @head_contents@ nil>
<master>
<property name="title">@page_title@</property>

<h2>@page_title@</h2>

@context_bar@

<hr>

<slave>
</if>
<else>
  <% # Setting the default attributes for page display.
     set bgcolor [ad_parameter -package_id [ad_acs_kernel_id] bgcolor acs-core-ui white]
     set text [ad_parameter -package_id [ad_acs_kernel_id] textcolor acs-core-ui black]	
     set attributes "bgcolor=\"$bgcolor\" text=\"$text\"" %>

<html>
<head>
@head_contents@
<title>@page_title@</title>
</head>
<body @attributes@>

<h2>@page_title@</h2>

@context_bar@

<hr>

<slave>

<hr>

<address><a href="mailto:@signatory@">@signatory@</a></address>
</body>
</html>
</else>









