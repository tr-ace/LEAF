<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

error_reporting(E_ERROR);

require_once 'globals.php';
require_once LIB_PATH . '/loaders/Leaf_autoloader.php';

$action = isset($_GET['a']) ? Leaf\XSSHelpers::xscrub($_GET['a']) : '';
$script = isset($_GET['s']) ? Leaf\XSSHelpers::scrubFilename(Leaf\XSSHelpers::xscrub($_GET['s'])) : '';

$main = new Smarty;
$main->left_delimiter = '{{';
$main->right_delimiter = '}}';

header('Content-type: application/javascript');
switch ($action) {
    case 'workflowStepModules':
        $stepID = (int)$_GET['stepID'];
        if ($script != ''
            && file_exists("scripts/workflowStepModules/{$script}.tpl")
            && is_numeric($stepID))
        {
            $vars = array(':stepID' => $stepID,
                          ':moduleName' => $script);
            $res = $db->prepared_query('SELECT * FROM step_modules
                                            WHERE stepID=:stepID
                                                AND moduleName=:moduleName', $vars);
            if(count($res) > 0) {
                $moduleConfig = Leaf\XSSHelpers::scrubObjectOrArray(json_decode($res[0]['moduleConfig']));
                $main->assign('moduleConfig', json_encode($moduleConfig));
            }

            $main->assign('stepID', $stepID);
            $main->display("scripts/workflowStepModules/{$script}.tpl");
        }
        break;
    default:
        break;
}