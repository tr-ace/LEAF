<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

/*
    Refreshes employee data into local orgchart
*/
echo "You are updating orgchart employees";
$currDir = dirname(__FILE__);

require_once $currDir.'/../globals.php';
require_once LIB_PATH . '/loaders/Leaf_autoloader.php';

?>
<script type="text/javascript" src="../../libs/js/jquery/jquery.min.js"></script>

<script>
$(document).ready(function () {
    refreshEmp();
});

function refreshEmp() {
    let CSRFToken = '<?= $_SESSION['CSRFToken'] ?>';

    $.ajax({
        type: 'POST',
        url: "../api/employee/refresh/batch",
        dataType: "json",
        data: {CSRFToken: CSRFToken},
        success: function(response) {
            console.log(response);

        },
        error: function (err) {
            console.log(err);
        },
        cache: false
    });
}
</script>