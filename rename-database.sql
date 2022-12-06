-- Author
-- https://gist.github.com/shivanshs9/3183fbd80bf08c44fc3b77305c9582cd

DROP PROCEDURE IF EXISTS moveTables;
DROP PROCEDURE IF EXISTS renameDatabase;

DELIMITER $$
CREATE PROCEDURE moveTables(_schemaName varchar(100), _newSchemaName varchar(100))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE table_name VARCHAR(64);
    DECLARE table_cursor CURSOR FOR SELECT information_schema.tables.table_name FROM information_schema.tables
                                    WHERE information_schema.tables.table_schema = _schemaName;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN table_cursor;

    table_loop: LOOP
        FETCH table_cursor INTO table_name;
        IF done THEN
            LEAVE table_loop;
        END IF;

        SET @sql = CONCAT('RENAME TABLE ', _schemaName, '.', table_name, ' TO ', _newSchemaName, '.', table_name);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DROP PREPARE stmt;
    END LOOP;

    CLOSE table_cursor;

END$$

CREATE PROCEDURE renameDatabase(_schemaName varchar(100), _newSchemaName varchar(100))
BEGIN
    SET @CREATE_TEMPLATE = 'CREATE DATABASE IF NOT EXISTS {DBNAME}';
    SET @DROP_TEMPLATE = 'DROP DATABASE {DBNAME}';

    -- Create new database
    SET @sql = REPLACE(@CREATE_TEMPLATE, '{DBNAME}', _newSchemaName);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DROP PREPARE stmt;
    -- Rename all the tables using the created procedure
    CALL moveTables(_schemaName, _newSchemaName);
    -- Drop old database
    SET @sql = REPLACE(@DROP_TEMPLATE, '{DBNAME}', _schemaName);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DROP PREPARE stmt;
END$$

DELIMITER ;

-- Below is an example command to run the procedure.
-- Make sure to change the arguments and uncomment the line before running it.
-- CALL renameDatabase('old_name', 'new_name');
