<master src="bm-master">
<property name="page_title">@page_title@</property>
<property name="context_bar_args">@context_bar_args@</property>

<if @url_unreachable_p@ eq "t">
<strong>Warning: We are not able to reach the url (@complete_url@) that you specified. Please make sure that you did not misspell the url.</strong>
</if>

<p>

<if @errmsg@ nil>

    You will be adding: 
    <ul> 
    <li>@local_title@
    <li><a href="@complete_url@">@complete_url@</a>
    </ul>
    <form action=bookmark-add-one-2 method=post>
    @export_form_vars_html@
    
    Please confirm that this is correct
    <ul>
    <table>
    <tr>
    <td>
    <input type=submit value="Ok, add the bookmark">
    </td>
    </tr>
    </table>
    </form>
    </ul>

</if><else>
    @errmsg@
</else>










