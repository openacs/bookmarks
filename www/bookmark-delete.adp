<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<include src="bookmark-header">

<if @contained_bookmarks:rowcount@ eq 1>
Are you sure that you want to delete the bookmark "@bookmark_title@"?
</if>
<else>
<strong>Are you sure that you want to delete all of the following bookmarks? The deletion can not be undone.</strong>
<p>
<multiple name="contained_bookmarks">
<%=[bm_repeat_string "&nbsp;" [expr @contained_bookmarks.indentation@ * 5]]%> @contained_bookmarks.local_title@ <br>
</multiple>
</else>


<p> 

<form method=post action="bookmark-delete-2">
<input type="hidden" name="bookmark_id" value="@bookmark_id@">
<input type="hidden" name="return_url" value="@return_url@">
<center>
<input type="submit" value="Yes, proceed">
</center>
</form>

