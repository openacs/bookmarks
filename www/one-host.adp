<master src="bm-master">
<property name="page_title">@page_title@</property>
<property name="context_bar_args">@context_bar_args@</property>

<ul>
<multiple name="user_urls">

<h4>@user_urls.name@</h4>

<group column="name">    
<li><a href="@user_urls.complete_url@">@user_urls.complete_url@</a> &nbsp; (@user_urls.local_title@)</li>
</group>

</multiple>
</ul>
