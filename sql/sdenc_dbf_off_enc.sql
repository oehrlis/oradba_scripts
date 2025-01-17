--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: sdenc_dbf_off_enc.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2024.03.05
--  Revision..:  
--  Purpose...: This PL/SQL script is designed to process database files, specifically
--              focusing on identifying files across different chunks based on their
--              sizes and preparing them for encryption commands. It dynamically
--              groups files into chunks, excluding files from specified tablespaces,
--              and generates ALTER DATABASE DATAFILE commands for encryption.
--              The script is optimized for readability and maintainability, with
--              clear separation of logic for collecting file information and
--              displaying chunk summaries.
--
--              The script is intended to be run in an Oracle Database environment
--              where it accesses the v$datafile and v$tablespace views to gather
--              file information. It excludes files from the SYSTEM, SYSAUX, and
--              UNDOTBS1 tablespaces by default, grouping the rest into chunks
--              based on a specified size limit and then outputs the necessary
--              commands for encryption.
--  Parameters: - l_chunk_size_gb (PLS_INTEGER): Defines the size of each chunk
--                in gigabytes. Default is set to 5 GB.
--              - l_excluded_tablespaces (VARCHAR2): Comma-separated list of
--                tablespaces to exclude from processing.
--  Notes.....: - Ensure that the Oracle environment has the v$datafile and
--                v$tablespace views accessible with the necessary permissions.
--              - This script generates commands for encryption but does not
--                execute them. It's essential to review these commands before
--                running them in a production environment.
--              - Adjust the 'l_chunk_size_gb' variable as needed to change the chunk size.
--              - The script uses DBMS_OUTPUT for displaying results. Ensure that
--                the client supports viewing the DBMS_OUTPUT buffer or use an
--                alternative method to capture the output.
--  Reference.: SYS (or grant manually to a DBA)
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
-- Anonymous PL/SQL Block to configure audit environment
SET SERVEROUTPUT ON
SET LINESIZE 160 PAGESIZE 200
SPOOL sdenc_dbf_off_enc.log
DECLARE
    -- Define a record type to store file information and calculated chunk information.
    TYPE r_file_rec_type IS RECORD (
            id        PLS_INTEGER,
            chunk_id  PLS_INTEGER,
            file_id   v$datafile.file#%TYPE,
            file_name v$datafile.name%TYPE,
            ts#       PLS_INTEGER,
            file_size v$datafile.bytes%TYPE -- Individual file size, used later to calculate chunk sizes.
    );
    -- Define a collection type to hold the file records.
    TYPE t_file_table_type IS
        TABLE OF r_file_rec_type INDEX BY PLS_INTEGER;
    t_files            t_file_table_type;

    -- Initialization of variables for operation.
    l_chunk_size_gb    PLS_INTEGER := 1;                -- Target chunk size in GB.
    l_chunk_size_bytes v$datafile.bytes%TYPE := l_chunk_size_gb * 1024 * 1024 * 1024; -- Convert GB to bytes for comparison.
    l_current_chunk_id PLS_INTEGER := 1;                -- To track current chunk ID.
    l_accumulated_size v$datafile.bytes%TYPE := 0;      -- To track the accumulated size of files within a chunk.
    l_id               PLS_INTEGER := 1;                -- To sequentially number each file record for identification.

BEGIN
    -- Collect file information from database while excluding specified tablespaces.
    << collect_file_info >> FOR r_file IN (
        SELECT
            df.file#,
            df.name,
            df.ts#,
            df.bytes
        FROM
                 v$datafile df
            JOIN v$tablespace ts ON df.ts# = ts.ts#
        WHERE
            ts.name NOT IN ( 'SYSTEM', 'SYSAUX', 'UNDOTBS1' )   -- Exclude specified tablespaces.
        ORDER BY
            df.bytes DESC
    ) LOOP
        -- Check if adding the current file would exceed the chunk size, indicating a new chunk should start.
        IF
            l_accumulated_size + r_file.bytes > l_chunk_size_bytes
            AND l_accumulated_size != 0
        THEN
            l_current_chunk_id := l_current_chunk_id + 1;       -- Move to the next chunk.
            l_accumulated_size := 0; -- Reset accumulated size for the new chunk.
        END IF;

        -- Store file information in the collection.
        t_files(l_id).id := l_id;
        t_files(l_id).chunk_id := l_current_chunk_id;
        t_files(l_id).file_id := r_file.file#;
        t_files(l_id).file_name := r_file.name;
        t_files(l_id).ts# := r_file.ts#;
        t_files(l_id).file_size := r_file.bytes;                -- Storing individual file size.

        -- Update accumulated size for the current chunk.
        l_accumulated_size := l_accumulated_size + r_file.bytes;
        l_id := l_id + 1; -- Increment the identifier for the next file record.
    END LOOP collect_file_info;

    -- Dynamically calculate and display chunk sizes based on collected file information.
    << display_chunks >> DECLARE
        l_last_chunk_id  PLS_INTEGER := 0;              -- To compare with the current chunk ID and determine when a chunk changes.
        l_last_file_id   v$datafile.file#%TYPE;         -- Keep track of the last processed file id for encryption statement output.
        l_chunk_size     v$datafile.bytes%TYPE := 0;    -- To calculate the total size of each chunk.
        l_file_count     PLS_INTEGER := 0;              -- To count the number of files in each chunk. NOSONAR
    BEGIN
        -- Output header for readability.
        sys.dbms_output.put_line('-----------------------------------------------------------');

        -- Loop through the files collection to output chunk information and encryption commands.
        << chunk_loop >> FOR i IN 1..t_files.count LOOP
            -- Check for a new chunk to output summary information of the previous chunk and reset counters.
            IF
                t_files(i).chunk_id != l_last_chunk_id
                AND l_last_chunk_id != 0
            THEN
                -- Output the ALTER DATABASE command for the last file of the previous chunk.
                sys.dbms_output.put_line('ALTER DATABASE DATAFILE '
                                         || l_last_file_id
                                         || ' ENCRYPT;');
                -- Output the summary information for the previous chunk.
                sys.dbms_output.put_line('-- Chunk ID '
                                         || l_last_chunk_id
                                         || ' files '
                                         || l_file_count
                                         || ' chunk size '
                                         || sys.dbms_xplan.format_size(l_chunk_size));

                sys.dbms_output.put_line('-----------------------------------------------------------');

                -- Reset counters for the new chunk.
                l_chunk_size := t_files(i).file_size;
                l_file_count := 1;
            ELSE
                -- If not a new chunk, output the ALTER DATABASE command for the file, accumulating chunk size and file count.
                IF l_last_chunk_id != 0 THEN
                    sys.dbms_output.put_line('ALTER DATABASE DATAFILE '
                                             || l_last_file_id
                                             || ' ENCRYPT;');
                END IF;

                l_chunk_size := l_chunk_size + t_files(i).file_size;
                l_file_count := l_file_count + 1;
            END IF;

            -- Update trackers for the next iteration.
            l_last_chunk_id := t_files(i).chunk_id;
            l_last_file_id := t_files(i).file_name;
        END LOOP chunk_loop;

        -- Output for the last chunk's information after completing the loop.
        sys.dbms_output.put_line('ALTER DATABASE DATAFILE '
                                 || l_last_file_id
                                 || ' ENCRYPT;');
        sys.dbms_output.put_line('-- Chunk ID '
                                 || l_last_chunk_id
                                 || ' files '
                                 || l_file_count
                                 || ' chunk size '
                                 || sys.dbms_xplan.format_size(l_chunk_size));

        sys.dbms_output.put_line('-----------------------------------------------------------');
    END display_chunks;

EXCEPTION
    -- Capture and output any exceptions that occur during execution .
    WHEN OTHERS THEN  -- NOSONAR
        sys.dbms_output.put_line('Error: '
                                 || sqlerrm
                                 || sys.dbms_utility.format_error_backtrace);
END;
/
SPOOL OFF
-- EOF -------------------------------------------------------------------------