<script>
var CSRFToken = '<!--{$CSRFToken}-->';

/*
    This is an example of how LEAF's Query and Grid systems work together to build a spreadsheet.

    The procedure:
    	1. Create a LeafFormQuery
    	2. Configure the grid, by assigning column headings
    	3. Execute the query.
    	
    Once the program has been completed, it can be accessed at the website:
    	https://[your server]/[your folder]/report.php?a=example
    	
*/
function getData() {
	// Create a new Query
	var query = new LeafFormQuery();
    
	// This would limit results to only show a specific service, by its serviceID
	//query.addTerm('serviceID', '=', 14);
	
	// Show requests that contain the word "example" for indicatorID 16 
	//query.addDataTerm('data', 16, 'LIKE', 'example');
	
	// Show requests that contain data for indicatorID 20, if it's greater or equal than 30000 
    //query.addDataTerm('data', 20, '>=', '30000');
	
	// Show requests that have not passed dependencyID 8 - "the quadrad/pentad/ELT step"
    //query.addDataTerm('dependencyID', 8, '=', 0);
	
	// Show requests that have NOT been deleted
	query.addTerm('deleted', '=', 0);
	
	// Show requests that have been submitted
	query.addTerm('submitted', '>', 0);
	
	// Show requests that match the "fte" categoryID
	query.addTerm('categoryID', 'RIGHT JOIN', 'fte');

    // Include service data
	query.join('service');
    
    /* Instead of building a query manually, the report builder can be used.
            * This requires a HTTP inspecting tool (eg: Developer mode / Firebug)
       query.importQuery('JSON query generated by the Report Builder goes here');
    */

	// This specifies the function to run if the query is valid.
	query.onSuccess(function(res) {
        var recordIDs = '';
        for (var i in res) {
        	// Currently need to store the resulting list of recordIDs as a CSV
            recordIDs += res[i].recordID + ',';
        }
        
        // Initialize the Grid
        var formGrid = new LeafFormGrid('grid'); // 'grid' maps to the associated HTML element ID
        
        // This enables the Export button
        formGrid.enableToolbar();
        
        // Required to initialize data for the grid
        formGrid.setDataBlob(res);
        
        // The column headers are configured here
        formGrid.setHeaders([
                                 {name: 'Service', indicatorID: 'service', editable: false, callback: function(data, blob) {
                                     $('#'+data.cellContainerID).html(blob[data.recordID].service);
                                 }},
                                 {name: 'Title', indicatorID: 'title', callback: function(data, blob) { // The Title field is a bit unique, and must be implemnted this way
                                     $('#'+data.cellContainerID).html(blob[data.recordID].title);
                                     $('#'+data.cellContainerID).on('click', function() {
                                         window.open('index.php?a=printview&recordID='+data.recordID, 'LEAF', 'width=800,resizable=yes,scrollbars=yes,menubar=yes');
                                     });
                                 }},
                                 
                                 // All other fields based on an indicatorID can use a simplifed syntax
                                 {name: 'HR Specialist', indicatorID: 256},
                                 {name: 'Closed-out', editable: false, indicatorID: 299},
                                 {name: 'Position Title', indicatorID: 355} // Note the last entry should not have an ending comma
                            ]);
        // Loads the CSV created earlier to help populate the spreadsheet
        formGrid.loadData(recordIDs);
    });
	
	// Executes the query
	query.execute();
}

// Ensures the webpage has fully loaded, before starting the program.
$(function() {
	
    getData();

});

</script>

<div id="grid"></div>