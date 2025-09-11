# PhD Dissertation Digital Workspace

This is the repository for my PhD Dissertation at Clemson University. It stores code scripts, metadata, and data files for the dissertation project. 

As a digital history research project, my dissertation uses methodologies of text mining to assess how newspapers discussed and promoted the spatiality and rhetoric of the American empire on display during world's fairs between the Civil War and World War II. Newspapers stories about international expositions informed how U.S. Americans thought of themselves and their role in the world, complicating their notions of foreigness and domesticity while also legitimizing U.S. imperialistic ambitions abroad. I hope to understand how the imagined geography of an American empire on display during those events changed over time in response to hemispheric relations and the growing significance of Latin America in the political discourse of U.S. state-building officials over time. By attending to the cultural commentary about the fairs, I argue that those events served as spaces of symbolic negotiation and legitimation of imperial projects between the United States and Latin America.

As of September 2025, I am in the process of completing the first step of data collection for the project. During this step, I am retrieving newspaper metadata from the Library of Congress digital collections using the website's API. For each one of the most significant fairs at the turn of the century, I am collecting newspaper articles that reference the event for the span of a year (before, during, and after the event is over). In the next phase of data colleciton, I will reprocess the JPG files of newspaper scans to extract machine-readable text data using an optical character recognition engine.

The content in this repository is organized in three major directories: code, data, and metadata. 

<h3>code</h3>
The <b>code</b> directory primarily hosts preprocessing scripts in R language that were used to retrieve newspaper metadata from Library of Congress for each significant world's fair betweeen 1876 and 1940. These scripts are stored in <b>data preprocessing</b>. In the next phase of the project, OCR processing scripts will be added to the code directory. Lastly, scripts that take OCRed text as training data for Word Embedding Models will be added. Any supporting scripts that are not part of the streamlined workflow of data collection, processing, and analysis will be stored in <b>Support scripts</b>.


<h3>metadata</h3>
This directory is organized in three subdirectories:

- <h4>API-Request-Info</h4>
Contains the "state.rds" files that store the current variables utilized for the API Request loop during preprocessing. The information on these files is updated every time a new API request is sent to ensure data integrity in case the request is suddenly interrupted due to connectivity issues. "state.rds" files will keep up-to-date information on crucial variables for the API Request loop to run properly, like total number of retrieved results, current query results page number, and current API url to be used during the GET request. When all the metadata have been fetched for a specific query, these files also reflect that and protect data integrity by avoiding duplicate requests. Lastly, the "LoC-API-JSON-Dictionary.txt" stores brief descriptions for each default variable that comes in the JSON Response object as well as their new titles, if any, in the final metadata file.

- <h4>Complete-Results</h4>
Contains the complete, clean, and date-sorted metadata files created through manipulation of the JSON Response object during the preprocessing step. There is one "newspaper-metadata.csv" file and one `newspaper-metadata.xlsx" file for each significant world's fair, and file names reflect the year of the event. The exception is "1915-newspaper-metadata.csv" and its "xlsx" version, as these contain metadata related to both San Francisco's 1915 World's Fair and San Diego's 1916 World's Fair. The use of "1915" in the file name was an arbitrary choice resulting from the methodological choice of examining these two expositions together for their specific historical context.

- <h4>Results-Count</h4>
Countains one "newspaper-count.csv" file for each world's fair. File names reflect the year of the event. These files have the aggregated query results from Chronicling America and grouped by newspaper and place of publication.


<h3>data</h3>
*Note: Currently, this directory only exists locally and is not available in the GitHub repository. Data files will be added as the project progresses.
This directoy contains the machine-readable text data to be analyzed in this project is organized in four subdirectories:

- <h4>raw OCR data</h4>: Contains the raw OCRed text data extracted from newspaper scans with matching query results. The files in this directoy contain noisy OCR data and are to be used for OCR quality validation.

- <h4>tokenized data</h4>: Contains the text data files for each world's fair. Each observation in a "token-data.csv" file is a word.

- <h4>TXT files</h4>: Contains the ".txt" files with the machine-readable text of each newspaper article collected from Chornicling America. Files to be added in this directory must go through post-processing to mitigate OCR issues to the extent that is possible.

- <h4>WEM</h4>: Contains the full corpus ".txt" files used to train Word Embedding Models and the models themselves stored in ".bin" files.
