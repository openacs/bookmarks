ad_page_contract {

    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id$
} {
    viewed_user_id:integer
    return_url
    search_text:notnull

} -validate {

    no_just_wildcard -requires {search_text:notnull} {
	if [regexp {^%+$} $search_text] {
	    ad_complain "Please search for more than just a wildcard."
	}
    }

} -properties {
    page_title:onevalue
    context:onevalue
    search_text:onevalue
    
    return_url:onevalue

    browsing_user_id:onevalue
    viewed_user_id:onevalue

    my_list:multirow
    others_list:multirow

} -return_errors error_list

if { [info exists error_list] } {
    set n_errors [llength $error_list]
    ad_return_template "complaint"
    return
}

set page_title "Searching for \"$search_text\""
set context [bm_context_bar_args [list $page_title] $viewed_user_id]

set package_id [ad_conn package_id]

set root_folder_id [bm_get_root_folder_id $package_id $viewed_user_id]

set browsing_user_id [ad_conn user_id]

set search_pattern "%[string toupper $search_text]%"

# this select gets all of the users bookmarks that match the user's request
template::list::create \
	-name my_list -multirow my_list \
	-elements {
		folder_names {
			label "Folders"
			html {nowrap ""}
		}
		title {
			label "Matches from your bookmark list"
			link_url_eval {$complete_url}
		}
		invoke {
			label "Edit"
			link_url_eval {[export_vars -base "bookmark_edit" {{bookmark_id $bookmark_id}} ]}
			link_html { title "Edit bookmark" }
			display_template {
				<img src="/resources/acs-subsite/Edit16.gif" width="16" height="16" border="0">
			}
		}
	} -no_data {
		Your search returned no matches in your bookmark list.
	}

db_multirow my_list bookmark_search_user {*SQL*}


# thie query searches across other peoples bookmarks that the browsing user
# has read permission on
template::list::create \
	-name others_list -multirow others_list \
	-elements {
		folder_names {
			label "Folders"
			html {nowrap ""}
		}
		title {
			label "Matches in other bookmark lists"
			link_url_eval {$complete_url}
		}
		invoke {
			label "Edit"
			link_url_eval {[export_vars -base "bookmark_edit" {bookmark_id viewed_user_id return_url} ]}
			link_html { title "Edit bookmark" }
			display_template {
				<if @others_list.admin_p@ eq "t">
				<img src="/resources/acs-subsite/Edit16.gif" width="16" height="16" border="0">
				</if>
			}
		}
	} -no_data {
		Your search returned no matches in other bookmark lists.
	}

db_multirow others_list bookmark_search_other {*SQL*}


# Take this "if" statement out once oracle has a bm_bookmarks_get_folder_names equivalent.
# Until then we won't display the folder_names column when using oracle.
set db_type [db_rdbms_get_type [db_current_rdbms]]
if {$db_type != "postgresql"} {
	template::list::element::set_property -list_name my_list \
		-element_name folder_names -property hide_p -value 1
	template::list::element::set_property -list_name others_list \
		-element_name folder_names -property hide_p -value 1
}
