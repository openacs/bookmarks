<master src="bm-master">
<property name="page_title">@page_title@</property>
<property name="context_bar_args">@context_bar_args@</property>

<% set img_html "<img border=0 src=pics/ftv2doc.gif align=top>"
set edit_tag "<font size=-1>Edit</font>"%>


<if @viewed_user_id@ eq @browsing_user_id@>
<if @my_list:rowcount@ gt "0">
Here are your bookmarks that match your search:
<p>
<multiple name="my_list">

@img_html@ <a href="@my_list.complete_url@">@my_list.title@</a> &nbsp; &nbsp;<a href=bookmark-edit?bookmark_id=@my_list.bookmark_id@&viewed_user_id=@viewed_user_id@>@edit_tag@</a><br>

</multiple>
</if>
<else>
We couldn't find any matches among your bookmarks.
</else>
</if>

<p>

<if @others_list:rowcount@ gt "0">
Here are other people's bookmarks that match your search:
<p>
<multiple name="others_list">

@img_html@ <a target=target_frame href="@others_list.complete_url@">@others_list.title@</a> <if @admin_p@ eq "t"> &nbsp; &nbsp; <a href=bookmark-edit?bookmark_id=@others_list.bookmark_id@&viewed_user_id=@viewed_user_id@>@edit_tag@</a></if> <br>

</multiple>
</if>
<else>
Your search returned zero matches in other bookmark lists.
</else>





