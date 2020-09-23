SET serveroutput ON
spool all_tables.txt
BEGIN
  FOR tab IN (SELECT * FROM all_tables WHERE owner='ROCKBANK')
  LOOP
    BEGIN
      EXECUTE immediate 'SELECT * FROM ' || tab.table_name;
        EXCEPTION
          WHEN OTHERS THEN
            dbms_output.put_line('Errors for table ' || tab.table_name || ': ' || SQLCODE);
    END;
  END LOOP;
END;
/
spool off;
SET serveroutput OFF
