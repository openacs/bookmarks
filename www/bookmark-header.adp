<!--Bookmarks header -->
<if @viewed_user_id@ ne "0">
      <div id="subnavbar-div">
        <div id="subnavbar-container">
          <div id="subnavbar">
   	   <div class="tab">
	     <a href=index>My Bookmarks</a>
	   </div>
	  <if @browsing_user_id@ eq @viewed_user_id@>
   	   <div class="tab">
	     <a href=bookmarks-export?viewed_user_id=@viewed_user_id@>Export</a>
	   </div>

	    <if @write_p@ eq "t">
                <div class="tab">
 		  <a href=bookmark-add-import?return_url=@return_url_urlenc@&viewed_user_id=@viewed_user_id@>Add / Import</a>	
                </div>
		<div class="tab">
	          <a href=folder-add?return_url=index&viewed_user_id=@viewed_user_id@>New Folder</a>
		</div>
            </if>
   	    <div class="tab">
             <a href=bookmarks-check?return_url=index&viewed_user_id=@viewed_user_id@>Check Links</a>
	    </div>
   	    <div class="tab">
 	     <a href="javascript:launch_window('@tree_url@')">Javascript</a>
	    </div>
	  </if>
   	    <div class="tab">
	     <a href=bookmarks-user-list>Other users</a> 
	    </div>
	    <if @root_admin_p@ eq "1">
   	     <div class="tab">
	      <a href="@permissions_url@">Permissions</a> 
	     </div>
	    </if>
	    <if @bookmarks_admin_p@ eq "1">
   	     <div class="tab">
	      <a href="admin">Admin</a>
	     </div>
	    </if>
          </div>
        </div>
      </div>
</if>

      <div id="subnavbar-body">

