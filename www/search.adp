<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<if @viewed_user_id@ eq @browsing_user_id@>
<if @my_list:rowcount@ gt "0">
Here are your bookmarks that match your search:
<p>
<multiple name="my_list">

<img border=0 src="pics/ftv2doc.gif" align="top"> 
<a href="@my_list.complete_url@">@my_list.title@</a>
&nbsp; &nbsp;<a href="bookmark-edit?bookmark_id=@my_list.bookmark_id@&viewed_user_id=@viewed_user_id@" title="Edit this bookmark"><img src="/resources/acs-subsite/Edit16.gif" height="16" width="16" alt="Edit" border="0"></a><br>

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

@img_html;noquote@ <a target=target_frame href="@others_list.complete_url@">@others_list.title@</a> <if @admin_p@ eq "t"> &nbsp; &nbsp; <a href=bookmark-edit?bookmark_id=@others_list.bookmark_id@&viewed_user_id=@viewed_user_id@>@edit_tag@</a></if> <br>

</multiple>
</if>
<else>
Your search returned zero matches in other bookmark lists.
</else>

<form action="search" method=post>
<input type="hidden" name="return_url" value="index">
<input type="hidden" name="viewed_user_id" value="@viewed_user_id@">

Search bookmarks for: <input name=search_text type=text size=20 value="@search_text@">
	<input type=submit value=Search>
</form>





