<?php
$currDir = dirname(__FILE__);
require_once $currDir.'/../globals.php';
require_once LIB_PATH . '/loaders/Leaf_autoloader.php';
// copied from FormWorkflow.php just to get us moved along.
$protocol = 'https';


$request_uri = str_replace(['/var/www/html/','/scripts'],'',$currDir);

$siteRoot = "{$protocol}://" . HTTP_HOST . '/' . $request_uri . '/';

// allow us to control if this is in days or minutes
if (!empty($_GET['minutes'])) {
    $timeAdjustment = 60;
} else {
    $timeAdjustment = 60 * 60 * 24;
}

// this was what the random function I found used.
$comment = '';

$getWorkflowStepsSQL = 'SELECT workflowID, stepID,stepTitle,stepData
FROM workflow_steps WHERE stepData LIKE \'%"AutomateEmailGroup":"true"%\';';
$getWorkflowStepsRes = $db->prepared_query($getWorkflowStepsSQL, []);

// do we have automated notification setup here
if (empty($getWorkflowStepsRes)) {
    // @todo: need to look at how other scripts output
    echo "No automated emails setup! \r\n";
    exit();
}
echo date('Y-m-d H:i:s')."\r\n";
// go over the selected events
foreach ($getWorkflowStepsRes as $workflowStep) {

    // get our data, we need to see how many days back we need to look.
    $eventDataArray = json_decode($workflowStep['stepData'], true, 3);

    // if we do not have automated email reminders skip on by, there could be a legacy entry in here.
    if(empty($eventDataArray['AutomatedEmailReminders'])){
        continue;
    }

    // DateSelected * DaysSelected * what is a day anyway= how many days to bug this person.
    $daysago = $eventDataArray['AutomatedEmailReminders']['DaysSelected'];

    // pass ?current=asdasd to get the present time for testing purposes
    $intialDaysAgoTimestamp = time() - ($daysago * $timeAdjustment);

    echo "Working on step: {$workflowStep['stepID']}, Initial Notification: ".date('Y-m-d H:i:s',$intialDaysAgoTimestamp)."\r\n";

    // step id, I think workflow id is also needed here
    $getRecordVar = [':stepID' => $workflowStep['stepID'], ':lastNotified' => date('Y-m-d H:i:s',$intialDaysAgoTimestamp)];

    // get the records that have not been responded to, had actions taken on, in x amount of time and never been responded to
    $getRecordSql = 'SELECT records.recordID, records.title, records.userID, `service`, records.`submitted`
        FROM records_workflow_state
        JOIN records ON records.recordID = records_workflow_state.recordID
        LEFT JOIN services USING(serviceID)
        WHERE records_workflow_state.stepID = :stepID
        AND lastNotified <= :lastNotified
        AND initialNotificationSent = 0
        AND deleted = 0;';

    $getRecordResInitial = $db->prepared_query($getRecordSql, $getRecordVar);

    foreach($getRecordResInitial as $getRecordResInitialKey=>$getRecordResInitialValue){
        $getRecordResInitial[$getRecordResInitialKey]['daysSince'] = $daysago;
    }

    // make sure additional days selected is set, this will be a required field moving forward however there is a chance this could not be set.
    if(empty($eventDataArray['AutomatedEmailReminders']['AdditionalDaysSelected'])) {
        $eventDataArray['AutomatedEmailReminders']['AdditionalDaysSelected'] = $eventDataArray['AutomatedEmailReminders']['DaysSelected'];
    }

    $addldaysago = $eventDataArray['AutomatedEmailReminders']['AdditionalDaysSelected'];
    $addDaysAgoTimestamp = time() - ($addldaysago * $timeAdjustment);

    $getRecordVar = [':stepID' => $workflowStep['stepID'], ':lastNotified' => date('Y-m-d H:i:s',$addDaysAgoTimestamp)];
    // get the records that have not been responded to, had actions taken on, in x amount of time and never been responded to
    $getRecordSql = 'SELECT records.recordID, records.title, records.userID, `service`, records.`submitted`
        FROM records_workflow_state
        JOIN records ON records.recordID = records_workflow_state.recordID
        LEFT JOIN services USING(serviceID)
        WHERE records_workflow_state.stepID = :stepID
        AND lastNotified <= :lastNotified
        AND initialNotificationSent = 1
        AND deleted = 0;';

    $getRecordResAfter = $db->prepared_query($getRecordSql, $getRecordVar);

    foreach($getRecordResAfter as $getRecordResAfterKey=>$getRecordResAfterValue){
        $getRecordResAfter[$getRecordResAfterKey]['daysSince'] = $addldaysago;
    }

    $getRecordRes = array_merge($getRecordResInitial,$getRecordResAfter);
    // make sure we have records to work with
    if (empty($getRecordRes)) {
        // @todo: need to look at how other scripts output errors
        echo "There are no records to be notified for this step! \r\n";
        continue;
    }

    // go through each and send an email
    foreach ($getRecordRes as $record) {

        // get the last action
        $getLastActionVar = [':recordID' => $record['recordID']];
        $getLastActionSql = "SELECT `time` FROM action_history WHERE recordID = :recordID ORDER BY `time` DESC LIMIT 1;";
        $getLastActionRes = $db->prepared_query($getLastActionSql, $getLastActionVar);

        if(!empty($getLastActionRes[0])){
            // if this is not empty use the time of the action
            $lastActionTime = $getLastActionRes[0]['time'];
        } else {
            // else this is where some test would show the action history may not be up to date for testing data, use the submitted time
            $lastActionTime = $record['submitted'];
        }

        // calculate the days
        $date1 = new DateTime(date('Y-m-d'));
        $date2 = new DateTime(date('Y-m-d',$lastActionTime));
        $interval = $date1->diff($date2);
        $lastActionDays = $interval->format('%a');

        // initialize the email
        $email = new Portal\Email();
        $email->setSiteRoot($siteRoot);
        // ive seen examples using the attachApproversAndEmail method and some had smarty vars and some did not.
        $title = strlen($record['title']) > 45 ? substr($record['title'], 0, 42) . '...' : $record['title'];

        // add in variables for the smarty template
        $email->addSmartyVariables(array(
            "daysSince" => $record['daysSince'],
            "actualDaysAgo" => $lastActionDays,
            "truncatedTitle" => $title,
            "fullTitle" => $record['title'],
            "recordID" => $record['recordID'],
            "service" => $record['service'],
            "stepTitle" => $workflowStep['stepTitle'],
            "comment" => $comment
        ));

        // need to get the emails sending to make sure this actually works!
        // need to get login for this user, as it stands it will default to "SYSTEM" which is not what we want here. $login
        $login->loginUser($record['userID']);
        $email->attachApproversAndEmail($record['recordID'],Portal\Email::AUTOMATED_EMAIL_REMINDER,$login);

        // update the notification timestamp, this could be moved to batch, just trying to get a prototype working
        $updateRecordsWorkflowStateVars = [
            ':recordID' => $record['recordID'],
            ':lastNotified' => date('Y-m-d H:i:s')
        ];
        $updateRecordsWorkflowStateSql = 'UPDATE records_workflow_state
                                            SET lastNotified=:lastNotified, initialNotificationSent=1
                                            WHERE recordID=:recordID';
        $db->prepared_query($updateRecordsWorkflowStateSql, $updateRecordsWorkflowStateVars);

        echo "Email sent for {$record['recordID']} \r\n";
    }
}
