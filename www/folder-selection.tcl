
# Get some data sources from the request processor
if { ![info exists viewed_user_id] } {
    set viewed_user_id [ad_conn user_id]
}

set package_id [ad_conn package_id]
set root_folder_id [bm_get_root_folder_id $package_id $viewed_user_id]

# Get the folder list
bm_folder_selection $viewed_user_id $root_folder_id $folder_p

