<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>
<include src="bookmark-header">

<if @user_list:rowcount@ eq 0>
    No other users have stored bookmarks on which you have read permission. <p>
</if><else>

Look at the most popular bookmarks:  <a href="bookmarks-most-popular">summarized by URL</a> or choose a user whose bookmarks you would like to view:

<ul>


<multiple name="user_list">

<li><a href="index?viewed_user_id=@user_list.viewed_user_id@">@user_list.first_names@ @user_list.last_name@</a> (@user_list.number_of_bookmarks@)

</multiple>

</ul>

</else>

