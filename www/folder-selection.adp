
    <%
	  if { [empty_string_p @default_id@] } {
	     set default_id @root_folder_id@
	  }    
	  set edit_form_option "<option value=\"@root_folder_id@\" [ad_decode @root_folder_id@ @default_id@ "selected" ""]>Top Level</option>\n"

    %>


    <multiple name="folders">
    <%	
	   append edit_form_option "<option value=@folders.bookmark_id@ [ad_decode @folders.bookmark_id@ @default_id@ "selected" ""]>[bm_repeat_string "&nbsp;" [expr @folders.indentation@ * 2]] @folders.local_title@ </option>\n"

    %>
    </multiple>

    <% 
       if {@folders:rowcount@ > 8} { 
	  set size_count 8
       } else {
	  set size_count [expr @folders:rowcount@ + 1]
       }
    %>

    <select size= <%= $size_count %> name=parent_id><%= $edit_form_option %></select>
