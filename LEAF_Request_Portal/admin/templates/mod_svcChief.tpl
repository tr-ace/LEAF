<style>
    .employeeSelectorInput {
        border: 1px solid #bbb;
    }
</style>

<div class="leaf-center-content">


    <!-- LEFT SIDE NAV -->
    <!--{assign var=left_nav_content value="
        <aside class='sidenav'>
            <div id='sideBar'>
                <button id='btn_uploadFile' class='usa-button leaf-width-12rem' onclick='syncServices();'>
                    Import from Nexus
                </button>
            </div>
        </aside>
    "}-->
    <!--{include file="partial_layouts/left_side_nav.tpl" contentLeft="$left_nav_content"}-->

    <main class="main-content">

        <h2>Service Chiefs</h2>

        <div>
            <div id="groupList"></div>
        </div>

        <div class="leaf-row-space"></div>

    </main>

    <!-- RIGHT SIDE NAV -->
    <!--{assign var=right_nav_content value="
        <aside class='sidenav-right'></aside>
    "}-->
    <!--{include file="partial_layouts/right_side_nav.tpl" contentRight="$right_nav_content"}-->

</div>


<!--{include file="site_elements/generic_xhrDialog.tpl"}-->
<!--{include file="site_elements/generic_simple_xhrDialog.tpl"}-->
<!--{include file="site_elements/generic_confirm_xhrDialog.tpl"}-->

<script type="text/javascript">
/* <![CDATA[ */

/**
 * Sync current list of services to that in the Nexus.
 */
function syncServices() {
    dialog_simple.setTitle('Importing from Nexus...');
    dialog_simple.show();
    $.ajax({
        type: 'GET',
        url: "../scripts/sync_services.php",
        success: function(response) {
            dialog_simple.setContent(response);
        },
        fail: function(error) {
            console.log(error);
        },
        cache: false
    });
    dialog_simple.setCancelHandler(function() {
        location.reload();
    });
}

/**
 * Create new service. [DEPRECATED]
 */
function createGroup() {
	/*
	dialog.clear();
    dialog.setTitle('Create new service');
    dialog.setContent('<b><span style="color: red">Before you proceed</span>, You should contact your Org Chart Administrators to determine whether the service needs to be added to the Org. Chart.</b>\
    		<br /><br />If the service is created in the Org. Chart, DO NOT create it here. Instead, click on "Sync Services" in the Admin Panel.\
    		<br /><br />Select Division: <select id="division"></select>\
    		<br /><br />Service Name: <input id="service" type="text"></input>');

    $.ajax({
    	type: 'GET',
    	url: '../api/service/quadrads',
    	success: function(res) {
    		for(let i in res) {
                $('#division').append('<option value="'+ res[i].groupID+'">'+ res[i].name +'</option>');
    		}
    	},
        cache: false
    });

    dialog.setSaveHandler(function() {
         $.ajax({
             type: 'POST',
             url: '../api/service',
             data: {'service': $('#service').val(),
            	 'groupID': $('#division').val(),
                 'CSRFToken': '<!--{$CSRFToken}-->'},
             success: function(res) {
                 location.reload();
             },
             cache: false
         });

        dialog.hide();
    });

    dialog.show();*/

    dialog_simple.setTitle('Create new service');
    dialog_simple.setContent('Changes to services must be made through Links->Nexus at the moment.');

    dialog_simple.show();
}

/**
 * Get members for given service.
 * @param {int} groupID - ID for group
 */
function getMembers(groupID = -1) {
    $.ajax({
        type: 'GET',
        url: '../api/system/updateService/' + groupID,
        success: function() {
            $.ajax({
                url: "../api/service/" + groupID + "/members",
                dataType: "json",
                success: function(response) {
                    $('#members' + groupID).fadeOut();
                    populateMembers(groupID, response);
                    $('#members' + groupID).fadeIn();
                },
                fail: function(error) {
                    console.log(error);
                },
                cache: false
            });
        },
        cache: false
    });
}

/**
 * Populate the members of a given service.
 * @param {int} groupID - ID of given group
 * @param {array} members - list object of all members in group
 */
function populateMembers(groupID = -1, members = []) {
    if (groupID < 0 || members.length === 0) {
        return;
    }
    $('#members' + groupID).html('');
    let memberCt = -1;
    for (let i in members) {
        if (members[i].active == 1 && members[i].backupID == null) {
            memberCt++;
        }
    }
    let countTxt = (memberCt > 0) ? (' + ' + memberCt + ' others') : '';
    for (let i in members) {
        if (members[i].active == 1 && members[i].backupID == null) {
            if ($('#members' + groupID).html('')) {
                $('#members' + groupID).append('<div class="groupUserFirst">' + toTitleCase(members[i].Fname) + ' ' + toTitleCase(members[i].Lname) + countTxt + '</div>');
            }
            $('#members' + groupID).append('<div class="groupUser">' + toTitleCase(members[i].Fname) + ' ' + toTitleCase(members[i].Lname) + ' <div>');
        }
    }
}

/**
 * Add user to portal
 * @param {int} groupID - ID of group
 * @param {int} userID - ID of user being added
 */
function addUser(groupID = -1, userID = -1) {
    if (groupID < 0 || userID < 0) {
        return;
    } else {
        $.ajax({
            type: 'POST',
            url: "../api/service/" + groupID + "/members",
            data: {'userID': userID,
                'CSRFToken': '<!--{$CSRFToken}-->'},
            cache: false
        });
    }
}

/**
 * Remove user from portal.
 * @param {int} groupID - ID of group
 * @param {int} userID - ID of user being removed
 */
function removeUser(groupID = -1, userID = -1) {
    if (groupID < 0 || userID < 0) {
        return;
    } else {
        $.ajax({
            type: 'DELETE',
            url: "../api/service/" + groupID + "/members/_" + userID + '?' +
                $.param({'CSRFToken': '<!--{$CSRFToken}-->'}),
            cache: false
        });
    }
}

/**
 * Import user from orgchart.
 * @param {int} serviceID - ID of service
 * @param {string} selectedUserName - Username being imported
 */
function importUser(serviceID = 0, selectedUserName = '') {
    if (serviceID === 0) {
        console.log('Invalid serviceID');
    }
    if (selectedUserName === '') {
        console.log('Invalid username');
    }
    $.ajax({
        type: 'POST',
        url: '<!--{$orgchartPath}-->/api/employee/import/_' + selectedUserName,
        data: {CSRFToken: '<!--{$CSRFToken}-->'},
        success: function(res) {
            if(!isNaN(res)) {
                addUser(serviceID, selectedUserName); // add identified user into portal.
            }
            else {
                alert(res);
            }
        },
        fail: function(err) {
            console.log(err);
        },
        cache: false
    });
}

/**
 * Delete given service.
 * @param {int} serviceID - ID of the service
 */
function deleteService(serviceID = 0) {
    if (serviceID === 0) {
        return;
    } else {
        $.ajax({
            type: 'DELETE',
            url: "../api/service/" + serviceID + '?' +
                $.param({'CSRFToken': '<!--{$CSRFToken}-->'}),
            success: function(response) {
                location.reload();
            },
            fail: function(error) {
                console.log(error);
            },
            cache: false
        });
    }
}

/**
 * Build the modal for when the user selects a service.
 * @param {int} serviceID - ID of service
 * @param {string} serviceName - Name of the service
 */
function initiateModal(serviceID = 0, serviceName = '') {
    if (serviceID === 0 || serviceName === '') {
        return;
    } else {
        $.ajax({
            type: 'GET',
            url: '../api/service/' + serviceID + '/members',
            success: function(res) {
                dialog.clear();
                let button_deleteGroup = '<button id="deleteGroup_'+serviceID+'" class="usa-button usa-button--secondary leaf-btn-small leaf-marginTop-1rem">Delete Group</button>';
                if(serviceID > 0) {
                    button_deleteGroup = '';
                }
                dialog.setContent(
                    '<div class="leaf-float-right"><button class="usa-button leaf-btn-small" onclick="viewHistory('+serviceID+')">View History</button></div>' +
                    '<a class="leaf-group-link" href="<!--{$orgchartPath}-->/?a=view_group&groupID=' + serviceID + '" title="groupID: ' + serviceID + '" target="_blank"><h2 role="heading" tabindex="-1">' + serviceName + '</h2></a><h3 role="heading" tabindex="-1" class="leaf-marginTop-1rem">Add Employee</h3><div id="employeeSelector"></div></br><div id="employees"></div>');
                $('#employees').html('<div id="employee_table" class="leaf-marginTopBot-1rem"></div>');
                let counter = 0;
                for(let i in res) {
                    // Check for active members to list
                    if (res[i].active == 1) {
                        if (res[i].backupID == null) {
                            let removeButton = '- <a href="#" class="text-secondary-darker leaf-font0-7rem leaf-remove-button" id="removeMember_' + counter + '">REMOVE</a>';
                            $('#employee_table').append('<a href="<!--{$orgchartPath}-->/?a=view_employee&empUID=' + res[i].empUID + '" class="leaf-user-link" title="' + res[i].empUID + ' - ' + res[i].userName + '" target="_blank"><div class="leaf-marginTop-halfRem leaf-bold leaf-font0-9rem">' + toTitleCase(res[i].Lname) + ', ' + toTitleCase(res[i].Fname) + '</a> <span class="leaf-font-normal">' + removeButton + '</span></div>');
                            // Check for Backups
                            for (let j in res) {
                                if (res[i].userName == res[j].backupID) {
                                    $('#employee_table').append('<div class="leaf-font0-8rem leaf-marginLeft-qtrRem">&bull; ' + toTitleCase(res[j].Fname) + ' ' + toTitleCase(res[j].Lname) + ' - <span class="text-secondary-darker leaf-font0-7rem">Backup for ' + toTitleCase(res[i].Fname) + ' ' + toTitleCase(res[i].Lname) + '</span></div>');
                                }
                            }
                            $('#removeMember_' + counter).on('click', function (userID) {
                                return function () {
                                    removeUser(serviceID, userID);
                                    dialog.hide();
                                };
                            }(res[i].userName));
                            counter++;
                        }
                    }
                }

                $('#deleteGroup_' + serviceID).on('click', function() {
                    dialog_confirm.setContent('Are you sure you want to delete this service?');
                    dialog_confirm.setSaveHandler(function() {
                        deleteService(serviceID);
                    });
                    dialog_confirm.show();
                });

                empSel = new nationalEmployeeSelector('employeeSelector');
                empSel.apiPath = '<!--{$orgchartPath}-->/api/?a=';
                empSel.rootPath = '<!--{$orgchartPath}-->/';
                empSel.outputStyle = 'micro';
                empSel.initialize();
                // Update on any action
                dialog.setCancelHandler(function() {
                    getMembers(serviceID);
                });
                dialog.setSaveHandler(function() {
                    if(empSel.selection != '') {
                        let selectedUserName = empSel.selectionData[empSel.selection].userName;
                        importUser(serviceID, selectedUserName);
                    }
                    dialog.hide();
                });

                dialog.show();
            },
            fail: function(error) {
                console.log(error);
            },
            cache: false
        });
    }
}

/**
 * Initiate widgets for each service
 * @param {int} serviceID - ID for service being represented
 * @param {string} serviceName - name of service being represented
 * @return function
 */
function initiateWidget(serviceID = 0, serviceName = '') {
    if (serviceID === 0 || serviceName === '') {
        return;
    } else {
        $('#' + serviceID).on('click keydown', function(e) {
            if (e.type === 'keydown' && e.which === 13 || e.type === 'click') {
                initiateModal(serviceID, serviceName);
            }
        });
    }
}

/**
 * Get list of present services in portal.
 */
function getGroupList() {
	$.when(
	    $.ajax({
	        type: 'GET',
	        url: '../api/service/quadrads',
	        cache: false
	    }),
        $.ajax({
            type: 'GET',
            url: '../api/service',
            cache: false
        })
     )
	.done(function(res1, res2) {
		let quadrads = res1[0];
		let services = res2[0];
	    for(let i in quadrads) {
	    	$('#groupList').append('<h2>'+ toTitleCase(quadrads[i].name) +'</h2><div class="leaf-displayFlexRow" id="group_'+ quadrads[i].groupID +'"></div>');
	    }
	    for(let i in services) {
	    	$('#group_' + services[i].groupID).append('<div tabindex="0" id="'+ services[i].serviceID +'" title="serviceID: '+ services[i].serviceID +'" class="groupBlockWhite">'
                    + '<h2 id="groupTitle'+ services[i].serviceID +'">'+ services[i].service +'</h2>'
                    + '<div id="members'+ services[i].serviceID +'"></div>'
                    + '</div>');
	    	initiateWidget(services[i].serviceID, services[i].service);
	    	populateMembers(services[i].serviceID, services[i].members);
	    }
	});
}

/**
 * View history of given group by ID.
 * @param {int} groupID - ID of given group
 */
function viewHistory(groupID = -1){
    if (groupID < 0) {
        return;
    }
    dialog_simple.setContent('');
    dialog_simple.setTitle('Service chief history');
	dialog_simple.show();
	dialog_simple.indicateBusy();

    $.ajax({
        type: 'GET',
        url: 'ajaxIndex.php?a=gethistory&type=service&id='+groupID,
        dataType: 'text',
        success: function(res) {
            dialog_simple.setContent(res);
            dialog_simple.indicateIdle();
        },
        fail: function(error) {
            console.log(error);
        },
        cache: false
    });
}

/**
 * Convert to title case.
 * @param {string} str - string to be converted
 */
function toTitleCase(str = '') {
    return (str == "" || str == null) ? "" : str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
}

// Define dialog boxes
let dialog;
let dialog_simple;
let dialog_confirm;
$(function() {
	dialog = new dialogController('xhrDialog', 'xhr', 'loadIndicator', 'button_save', 'button_cancelchange');
    dialog_simple = new dialogController('simplexhrDialog', 'simplexhr', 'simpleloadIndicator', 'simplebutton_save', 'simplebutton_cancelchange');
    dialog_confirm = new dialogController('confirm_xhrDialog', 'confirm_xhr', 'confirm_loadIndicator', 'confirm_button_save', 'confirm_button_cancelchange');
    getGroupList();
});

/* ]]> */
</script>
