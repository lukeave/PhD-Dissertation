# PhD Dissertation Digital Workspace

This is the repository for my PhD Dissertation at Clemson University. Please note that the file structure, description, and intended purpose of each script, data table, and metadata kept in this repository may change significantly as the research questions that inform the project's direction evolve over time. This README file is consequently a living document itself.

As a digital history project, my dissertation uses methodologies of text mining to assess how newspapers discussed and promoted the spatiality and rhetoric of the American empire on display during world's fairs between the Civil War and World War II. Newspapers stories about international expositions informed how U.S. Americans thought of themselves and their role in the world, complicating their notions of foreigness and domesticity while also legitimizing U.S. imperialistic ambitions abroad. I hope to understand how the imagined geography of an American empire on display during those events changed over time in response to hemispheric relations and the growing significance of Latin America in the political discourse of U.S. state-building officials over time. By attending to the cultural commentary about the fairs, I argue that those events served as spaces of symbolic negotiation and legitimation of imperial projects between the United States and Latin America.

As of September 2025, I am in the process of completing the first step of data collection for the project. During this step, I am retrieving newspaper metadata from the Library of Congress digital collections using the website's API. For each one of the most significant fairs at the turn of the century, I am collecting newspaper articles that reference the event for the span of a year or more (before, during, and after the event is over). In the next phase of data colleciton, I will reprocess the JPG files of newspaper scans to extract machine-readable text data using an optical character recognition engine.

The content in this repository is organized in three major directories: code, data, and metadata.

## code

- #### data preprocessing:

    Contains the preprocessing scripts in R that were used to retrieve newspaper metadata from the Library of Congress for each significant world's fair between 1876 and 1940 through the website's API.

- #### OCR processing:

    After all the newspaper metadata is retrieved and preprocessed, this subdirectory will hold the code scripts for OCR extraction, tokenization, and other text data post-processing steps. Currently, this subdirectory only exists locally.

- #### WEM training:

    This subdirectory will store the scripts that take post-processed OCRed text as training data for Word Embedding Models.

- #### support scripts:

    Any supporting scripts that are not integral parts of the streamlined workflow of data collection, processing, and analysis will be stored in this subdirectory.



## metadata
The files in this directory derive from the manipulation of JSON data acquired through API requests to the Library of Congress. These files are stored across five subdirectories:

- #### API-Request-Info:

    Contains the ``state.rds`` files that store up-to-date values of variables utilized during the API Request loop in the preprocessing stage. The information in these files is updated every time a new API Request is submitted to maintain data integrity in case the request is suddenly interrupted due to connectivity issues. ``state.rds`` files will keep up-to-date information on crucial variables for the API Request loop to run properly, like total number of retrieved results, current query results page number, and current API url to be used during the GET request. When all the metadata have been fetched for a specific query, these files are not deleted; rather, they are kept up to date to protect data integrity and avoid duplicate requests. Finally, the ``LoC-API-JSON-Dictionary.txt`` stores brief descriptions for each default variable that comes in the JSON Response object as well as their new titles, if any, in the final metadata file.


- #### Complete-Results:

    Contains the complete, clean, and date-sorted metadata files created through manipulation of the JSON Response object during the preprocessing step. There is one ``newspaper-metadata.csv`` file and one ``newspaper-metadata.xlsx`` file for each significant world's fair, and file names reflect the year of the event. The exception is ``1915-newspaper-metadata.csv`` and its ``xlsx`` version, as these contain metadata related to both San Francisco's 1915 World's Fair and San Diego's 1916 World's Fair. The use of "1915" in the file name was an arbitrary choice resulting from the methodological choice of examining these two expositions together for their specific historical context.

- #### Results-Count:

    Contains one ``newspaper-count.csv`` file for each world's fair. File names reflect the year of the event. These files have the aggregated query results from Chronicling America and grouped by newspaper and place of publication.

- #### Partial-Results:

    This directory is used when an API Request is interrupted before all the query results are retrieved. Interrupted Requests must be complete in multiple sessions, and ``newspaper-metadata_partial.csv`` files store partial results fetched during an incomplete API Request session. The correspondent ``API-Request-Info/*-state.rds`` file serves as a point of reference for the next Request to be submitted. New results will be appended to the existing file in this directory until no more results are available. When the Request is complete and the final metadata file is created in the ``Complete-Results/`` directory, partial results files are programmatically deleted. When no partial files exist, this directory does not show in the Git repository.

- #### Missing-Results:

    In rare circumstances, API Requests might skip matching results to the query due to problems in the HTTPS connection, internal corrupted indexing in the LoC digital collections, or other similar issue. During preprocessing and manipulation of the JSON object, the integrity of resulting metadata files is verified by comparing the query result index of retrieved observations to the expected numerical sequence. If an index turns out to be missing from a metadata file, that file is moved into this directory for troubleshooting and manual integrity verification. After missing results and their respective index numbers are recovered and validated, the metadata file is moved back into ``Complete-Results/``.


## data
*Note: Currently, this directory only exists locally and is not available in the GitHub repository. Data files will be added as the project progresses.
This directoy will store machine-readable text data for analysis, and these data files will be structured and organized under four main categories:

- #### raw OCR data:
    The raw OCRed text data extracted from newspaper scans with matching query results. The files in this directoy will contain noisy OCR data and are to be used for OCR quality control and acurracy confidence validation.

- #### tokenized data:

    The text data files for each world's fair. Each observation in a ``token-data.csv`` file is an n-gram token and it should include relevant metadata for quantitative analysis. Tokenized text data can be used for the most basic types of text anlysis, like relative term frequency.

- #### TXT files:

    The tidy, individual ``.txt`` files with the machine-readable text of each newspaper article collected from Chornicling America. Files to be added in this directory must go through post-processing to mitigate OCR issues.

- #### WEM:

    The full corpus ``.txt`` files to be used as training data for Word Embedding Models and the models themselves stored in ``.bin`` files.