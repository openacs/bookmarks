<master>
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>

<if @viewed_user_id@ eq @browsing_user_id@>
	<listtemplate name="my_list"></listtemplate>
</if>

<p><listtemplate name="others_list"></listtemplate>

<form action="search" method="post">
	<input type="hidden" name="return_url" value="index">
	<input type="hidden" name="viewed_user_id" value="@viewed_user_id@">

	Search bookmarks for: <input name="search_text" type="text" size="20" value="@search_text@">
	<input type="submit" value="Search">
</form>
